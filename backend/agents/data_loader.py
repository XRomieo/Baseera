"""
agents/data_loader.py
Loads all 5 mock data sources and returns them as formatted strings
for injection into the Gemini prompt.
"""

import json
import os
import pandas as pd
from pathlib import Path

MOCK_DATA_DIR = Path(__file__).parent.parent / "mock_data"


def load_warehouse_stock() -> str:
    """Load warehouse_stock.csv and return as formatted string."""
    csv_path = MOCK_DATA_DIR / "warehouse_stock.csv"
    df = pd.read_csv(csv_path)
    lines = ["=== WAREHOUSE STOCK CSV (Data Date: 2026-05-17 — 3 DAYS OLD) ==="]
    lines.append(f"Columns: {', '.join(df.columns.tolist())}")
    lines.append("")
    for _, row in df.iterrows():
        lines.append(
            f"  Product: {row['product_name']} | Stock: {row['stock_units']} units | "
            f"Location: {row['warehouse_location']} | Last Updated: {row['last_updated']}"
        )
    lines.append("")
    lines.append(f"[WARNING] This data was last updated on 2026-05-17. Today is 2026-05-20. "
                 f"Data is 3 days old and may not reflect current inventory.")
    return "\n".join(lines)


def load_supplier_email() -> str:
    """Load supplier_email.json and return as formatted string."""
    json_path = MOCK_DATA_DIR / "supplier_email.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    meta = data["email_metadata"]
    body = data["email_body"]
    order = data["order_details"]
    
    lines = ["=== SUPPLIER EMAIL (Received: 2026-05-20 09:14 PKT) ==="]
    lines.append(f"From: {meta['from_name']} <{meta['from']}>")
    lines.append(f"Subject: {meta['subject']}")
    lines.append(f"Date: {meta['date']} {meta['time']} {meta['timezone']}")
    lines.append(f"Priority: {meta['priority']}")
    lines.append("")
    for para in body["paragraphs"]:
        lines.append(f"  {para}")
        lines.append("")
    lines.append(f"Order Details:")
    lines.append(f"  - Order ID: {order['order_id']}")
    lines.append(f"  - Product: {order['product']} (Qty: {order['ordered_quantity']} units)")
    lines.append(f"  - Original Delivery: {order['original_delivery_date']}")
    lines.append(f"  - REVISED Delivery: {order['revised_delivery_date']} (+{order['delay_days']} days)")
    lines.append(f"  - Reason: {order['reason']}")
    lines.append(f"  - Total Order Value: PKR {order['total_order_value_pkr']:,}")
    return "\n".join(lines)


def load_sales_dashboard() -> str:
    """Load sales_dashboard.json and return as formatted string."""
    json_path = MOCK_DATA_DIR / "sales_dashboard.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    product = data["basmati_rice_5kg"]
    summary = product["summary"]
    projection = product["inventory_projection"]
    alerts = data["alerts"]
    
    lines = ["=== SALES DASHBOARD (Real-Time POS Data, Report Date: 2026-05-20) ==="]
    lines.append(f"Product: {product['product_name']} (SKU: {product['sku']})")
    lines.append("")
    lines.append("Daily Sales (Last 7 Days):")
    for day in product["daily_sales"]:
        lines.append(f"  {day['date']}: {day['units_sold']} units sold | Revenue: PKR {day['revenue_pkr']:,}")
    lines.append("")
    lines.append(f"Summary:")
    lines.append(f"  - Total units sold (7 days): {summary['total_units_sold_7_days']}")
    lines.append(f"  - Average daily sales: {summary['average_daily_sales']} units/day")
    lines.append(f"  - Last 3 days sales: {summary['last_3_days_units']} units (since warehouse snapshot)")
    lines.append(f"  - Stock velocity: {summary['stock_velocity_category']}")
    lines.append("")
    lines.append(f"Inventory Projection:")
    lines.append(f"  - Warehouse-listed stock: {projection['current_listed_stock']} units (OUTDATED)")
    adj = projection["BUT_considering_3_days_elapsed_since_last_count"]
    lines.append(f"  - ESTIMATED actual stock (adjusting for 3-day sales): ~{adj['estimated_current_stock']} units")
    lines.append(f"  - Days until stockout at current rate: ~{adj['adjusted_days_until_stockout']:.1f} days")
    lines.append("")
    for alert in alerts:
        lines.append(f"⚠ ALERT [{alert['severity']}]: {alert['message']}")
    return "\n".join(lines)


def load_customer_complaints() -> str:
    """Load customer_complaints.json and return as formatted string."""
    json_path = MOCK_DATA_DIR / "customer_complaints.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    meta = data["complaints_metadata"]
    finding = data["critical_finding"]
    stats = data["summary_statistics"]
    comparison = data["comparison_to_baseline"]
    
    lines = ["=== CUSTOMER COMPLAINTS REPORT (Last 24 Hours: 2026-05-19 to 2026-05-20) ==="]
    lines.append(f"Total Complaints: {meta['total_complaints_received']}")
    lines.append(f"Product: {meta['product_name']}")
    lines.append(f"Category: {meta['complaint_category']}")
    lines.append(f"Channels: Website ({meta['channel_breakdown']['website']}), "
                 f"Mobile App ({meta['channel_breakdown']['mobile_app']}), "
                 f"WhatsApp ({meta['channel_breakdown']['whatsapp_support']})")
    lines.append("")
    lines.append(f"CRITICAL FINDING: {finding['finding']}")
    lines.append(f"Implication: {finding['implication']}")
    lines.append(f"Contradiction Flag: {finding['contradiction_flag']}")
    lines.append("")
    lines.append("Sample Complaints:")
    for c in data["complaints"][:5]:
        lines.append(f"  [{c['timestamp']}] Customer {c['customer_id']}: \"{c['message'][:100]}...\"")
    lines.append(f"  ... and {meta['total_complaints_received'] - 5} more similar complaints")
    lines.append("")
    lines.append(f"Statistics:")
    lines.append(f"  - Avg complaints/hour: {stats['avg_complaints_per_hour']}")
    lines.append(f"  - Estimated lost revenue: PKR {stats['estimated_lost_revenue_pkr']:,}")
    baseline = comparison.get('avg_daily_complaints_last_30_days', comparison.get('avg_complaints_per_hour_last_30_days', 2.3))
    lines.append(f"  - vs 30-day baseline ({baseline} avg/day): "
                 f"{comparison['increase_factor']}x INCREASE — ANOMALY DETECTED")
    return "\n".join(lines)


def load_market_news() -> str:
    """Load market_news_feed.json and return as formatted string."""
    json_path = MOCK_DATA_DIR / "market_news_feed.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    intel = data["market_intelligence_summary"]
    
    lines = ["=== MARKET NEWS FEED (Punjab Region, Aggregated: 2026-05-20) ==="]
    lines.append(f"Crisis Level: {intel['crisis_level']}")
    lines.append(f"Transport Disruption: ONGOING since {intel['strike_start_date']}")
    lines.append(f"Estimated Resolution: {intel['estimated_resolution_date']} (Total Delay: {intel['total_delay_days']} days)")
    lines.append(f"Most Affected: {', '.join(intel['most_affected_commodities'])}")
    lines.append("")
    for item in data["news_items"]:
        lines.append(f"[{item['source']}] [{item['published_at'][:10]}] {item['headline']}")
        lines.append(f"  Impact: {item['impact_assessment']} | Relevance: {item['relevance_to_retail']}")
        lines.append(f"  Summary: {item['summary'][:200]}...")
        lines.append("")
    return "\n".join(lines)


def load_all_sources() -> dict:
    """
    Load all 5 data sources and return a dict of source_name -> formatted_content.
    """
    return {
        "warehouse_stock.csv": load_warehouse_stock(),
        "supplier_email.json": load_supplier_email(),
        "sales_dashboard.json": load_sales_dashboard(),
        "customer_complaints.json": load_customer_complaints(),
        "market_news_feed.json": load_market_news(),
    }
