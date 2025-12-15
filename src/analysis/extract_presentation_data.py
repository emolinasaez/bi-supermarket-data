"""
Extract Gold Layer Metrics for Executive Presentation

This script queries all Gold tables and extracts key metrics
to populate the interactive HTML presentation.

Output: presentation_data.json
"""

import duckdb
import json
from pathlib import Path
from datetime import datetime
from decimal import Decimal

# Database path
DB_PATH = r'D:\github_projects\bi-supermarket-data\dwh\retail_analytics.duckdb'

def connect_db():
    """Connect to DuckDB"""
    return duckdb.connect(str(DB_PATH), read_only=True)

def get_financial_metrics(conn):
    """Extract Financial Performance metrics"""
    
    # Overall KPIs
    kpis = conn.execute("""
        SELECT 
            SUM(total_gross_revenue) as total_gross_revenue,
            SUM(total_returns) as total_returns,
            SUM(total_net_revenue) as total_net_revenue,
            SUM(total_real_loss) as total_real_loss,
            SUM(total_unreported_loss) as total_unreported_loss,
            SUM(adjusted_profit) as total_adjusted_profit,
            AVG(adjusted_profit_margin_pct) as avg_profit_margin,
            AVG(avg_return_rate_pct) as avg_return_rate,
            AVG(loss_rate_pct) as avg_loss_rate
        FROM main_gold.financial_kpis
    """).fetchone()
    
    # Monthly trend
    monthly_trend = conn.execute("""
        SELECT 
            year_month,
            total_net_revenue,
            total_real_loss,
            adjusted_profit,
            adjusted_profit_margin_pct
        FROM main_gold.financial_kpis
        ORDER BY year_month
    """).fetchall()
    
    # Loss breakdown by category
    loss_by_category = conn.execute("""
        SELECT 
            loss_category,
            SUM(total_units_lost) as units_lost,
            SUM(unreported_loss_cogs) as unreported_loss
        FROM main_gold.loss_impact_analysis
        GROUP BY loss_category
        ORDER BY unreported_loss DESC
    """).fetchall()
    
    return {
        'total_gross_revenue': float(kpis[0]) if kpis[0] else 0,
        'total_returns': float(kpis[1]) if kpis[1] else 0,
        'total_net_revenue': float(kpis[2]) if kpis[2] else 0,
        'total_real_loss': float(abs(kpis[3])) if kpis[3] else 0,
        'total_unreported_loss': float(abs(kpis[4])) if kpis[4] else 0,
        'total_adjusted_profit': float(kpis[5]) if kpis[5] else 0,
        'avg_profit_margin': float(kpis[6]) if kpis[6] else 0,
        'avg_return_rate': float(kpis[7]) if kpis[7] else 0,
        'avg_loss_rate': float(kpis[8]) if kpis[8] else 0,
        'monthly_trend': [
            {
                'month': row[0],
                'revenue': round(row[1], 2),
                'loss': round(abs(row[2]), 2) if row[2] else 0,
                'profit': round(row[3], 2),
                'margin': round(row[4], 2) if row[4] else 0
            }
            for row in monthly_trend
        ],
        'loss_by_category': [
            {
                'category': row[0],
                'units': int(row[1]),
                'amount': round(abs(row[2]), 2) if row[2] else 0
            }
            for row in loss_by_category
        ]
    }

def get_customer_metrics(conn):
    """Extract Customer Analytics metrics"""
    
    # RFM Segmentation
    rfm_segments = conn.execute("""
        SELECT 
            customer_segment,
            COUNT(*) as num_customers,
            SUM(monetary_value) as total_revenue,
            AVG(monetary_value) as avg_revenue_per_customer,
            AVG(frequency) as avg_frequency
        FROM main_gold.customer_rfm
        GROUP BY customer_segment
        ORDER BY total_revenue DESC
    """).fetchall()
    
    # CLV Distribution
    clv_stats = conn.execute("""
        SELECT 
            value_tier,
            COUNT(*) as num_customers,
            SUM(clv_3year) as total_clv,
            AVG(clv_3year) as avg_clv
        FROM main_gold.customer_lifetime_value
        GROUP BY value_tier
        ORDER BY total_clv DESC
    """).fetchall()
    
    # Top customers
    top_customers = conn.execute("""
        SELECT 
            customer_id,
            country,
            customer_segment,
            total_revenue,
            total_orders,
            clv_3year
        FROM main_gold.customer_lifetime_value
        ORDER BY clv_3year DESC
        LIMIT 10
    """).fetchall()
    
    return {
        'total_customers': sum(row[1] for row in rfm_segments),
        'rfm_segments': [
            {
                'segment': row[0],
                'count': int(row[1]),
                'revenue': round(row[2], 2),
                'avg_revenue': round(row[3], 2),
                'avg_frequency': round(row[4], 2)
            }
            for row in rfm_segments
        ],
        'clv_tiers': [
            {
                'tier': row[0],
                'count': int(row[1]),
                'total_clv': round(row[2], 2),
                'avg_clv': round(row[3], 2)
            }
            for row in clv_stats
        ],
        'top_customers': [
            {
                'customer_id': int(row[0]),
                'country': row[1],
                'segment': row[2],
                'revenue': round(row[3], 2),
                'orders': int(row[4]),
                'clv_3year': round(row[5], 2)
            }
            for row in top_customers
        ]
    }

def get_operational_metrics(conn):
    """Extract Operational Excellence metrics"""
    
    # Loss control summary
    loss_control = conn.execute("""
        SELECT 
            COUNT(DISTINCT year_week) as total_weeks,
            AVG(units_lost) as avg_weekly_loss,
            STDDEV(units_lost) as stddev_weekly_loss,
            MAX(units_lost) as max_weekly_loss,
            SUM(CASE WHEN control_status LIKE '%Out of Control%' THEN 1 ELSE 0 END) as weeks_out_of_control,
            SUM(CASE WHEN control_status LIKE '%Black Swan%' THEN 1 ELSE 0 END) as black_swan_events
        FROM main_gold.inventory_loss_control
    """).fetchone()
    
    # Weekly trend
    weekly_trend = conn.execute("""
        SELECT 
            year_week,
            SUM(units_lost) as units_lost,
            SUM(financial_loss) as financial_loss,
            MAX(z_score) as max_z_score,
            MAX(control_status) as status
        FROM main_gold.inventory_loss_control
        GROUP BY year_week
        ORDER BY year_week
    """).fetchall()
    
    # Black swan events
    black_swans = conn.execute("""
        SELECT 
            year_week,
            loss_category,
            units_lost,
            financial_loss,
            z_score
        FROM main_gold.inventory_loss_control
        WHERE control_status LIKE '%Black Swan%' OR control_status LIKE '%Out of Control%'
        ORDER BY ABS(z_score) DESC
        LIMIT 5
    """).fetchall()
    
    return {
        'total_weeks': int(loss_control[0]),
        'avg_weekly_loss': round(loss_control[1], 2),
        'stddev_weekly_loss': round(loss_control[2], 2),
        'max_weekly_loss': round(loss_control[3], 2),
        'weeks_out_of_control': int(loss_control[4]),
        'black_swan_events': int(loss_control[5]),
        'ucl_3sigma': round(loss_control[1] + 3 * loss_control[2], 2),
        'weekly_trend': [
            {
                'week': row[0],
                'units': round(row[1], 2),
                'loss': round(abs(row[2]), 2) if row[2] else 0,
                'z_score': round(row[3], 2) if row[3] else 0,
                'status': row[4]
            }
            for row in weekly_trend
        ],
        'black_swans': [
            {
                'week': row[0],
                'category': row[1],
                'units': round(row[2], 2),
                'loss': round(abs(row[3]), 2) if row[3] else 0,
                'z_score': round(row[4], 2)
            }
            for row in black_swans
        ]
    }

def get_product_metrics(conn):
    """Extract Product Intelligence metrics"""
    
    # Product classification
    product_classification = conn.execute("""
        SELECT 
            product_classification,
            COUNT(*) as num_products,
            SUM(total_revenue) as total_revenue,
            AVG(return_rate_pct) as avg_return_rate
        FROM main_gold.product_performance
        GROUP BY product_classification
        ORDER BY total_revenue DESC
    """).fetchall()
    
    # Top performers (Stars)
    top_products = conn.execute("""
        SELECT 
            stock_code,
            canonical_description,
            total_revenue,
            total_units_sold,
            return_rate_pct,
            product_classification
        FROM main_gold.product_performance
        WHERE product_classification = 'Star Product'
        ORDER BY total_revenue DESC
        LIMIT 10
    """).fetchall()
    
    # Zombies (underperformers)
    zombie_products = conn.execute("""
        SELECT 
            stock_code,
            canonical_description,
            total_revenue,
            return_rate_pct
        FROM main_gold.product_performance
        WHERE product_classification = 'Zombie Product'
        ORDER BY total_revenue ASC
        LIMIT 10
    """).fetchall()
    
    return {
        'total_products': sum(row[1] for row in product_classification),
        'classification': [
            {
                'type': row[0],
                'count': int(row[1]),
                'revenue': round(row[2], 2),
                'avg_return_rate': round(row[3], 2) if row[3] else 0
            }
            for row in product_classification
        ],
        'top_products': [
            {
                'code': row[0],
                'name': row[1],
                'revenue': round(row[2], 2),
                'units': int(row[3]),
                'return_rate': round(row[4], 2) if row[4] else 0,
                'classification': row[5]
            }
            for row in top_products
        ],
        'zombie_products': [
            {
                'code': row[0],
                'name': row[1],
                'revenue': round(row[2], 2),
                'return_rate': round(row[3], 2) if row[3] else 0
            }
            for row in zombie_products
        ]
    }

def main():
    """Main execution"""
    print("🔍 Extracting Gold Layer Metrics...")
    
    conn = connect_db()
    
    try:
        # Extract all metrics
        data = {
            'metadata': {
                'generated_at': datetime.now().isoformat(),
                'database': str(DB_PATH),
                'version': '1.0.0'
            },
            'financial': get_financial_metrics(conn),
            'customer': get_customer_metrics(conn),
            'operational': get_operational_metrics(conn),
            'product': get_product_metrics(conn)
        }
        
        # Save to JSON
        output_path = Path(r'D:\github_projects\bi-supermarket-data\docs\presentation_data.json')
        output_path.parent.mkdir(parents=True, exist_ok=True)
        
        # Custom JSON encoder for Decimal types
        class DecimalEncoder(json.JSONEncoder):
            def default(self, obj):
                if isinstance(obj, Decimal):
                    return float(obj)
                return super().default(obj)
        
        with open(output_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, ensure_ascii=False, cls=DecimalEncoder)
        
        print(f"✅ Data extracted successfully!")
        print(f"📄 Output: {output_path}")
        print(f"\n📊 Summary:")
        print(f"   - Total Revenue: £{data['financial']['total_net_revenue']:,.2f}")
        print(f"   - Unreported Losses: £{data['financial']['total_unreported_loss']:,.2f}")
        print(f"   - Total Customers: {data['customer']['total_customers']:,}")
        print(f"   - Total Products: {data['product']['total_products']:,}")
        print(f"   - Black Swan Events: {data['operational']['black_swan_events']}")
        
    finally:
        conn.close()

if __name__ == '__main__':
    main()
