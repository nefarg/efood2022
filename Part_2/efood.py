import pandas as pd
import numpy as np


def process_data(filename):
    orders = pd.read_csv(filename)
    cleaned_orders = cleaning(orders)
    cleaned_orders, summarized_info = transform(cleaned_orders)
    cleaned_orders.to_csv('transformed_orders.csv', index=False)
    summarized_info.to_csv('summarized_info.csv')


def cleaning(orders):
    # Drop records with 'nulls'
    remove_nulls = orders.dropna()

    # Drop duplicates: across all columns and on order_id
    drop_dup = remove_nulls \
        .drop_duplicates() \
        .drop_duplicates(subset=['order_id'], keep='first')

    # Keep orders with  positive amount
    cleaned_orders = drop_dup[drop_dup['amount'] > 0]
    return cleaned_orders


def transform(cleaned_orders):
    # Find days of orders
    cleaned_orders['order_timestamp'] = pd.to_datetime(cleaned_orders['order_timestamp'],
                                                       format='%Y-%m-%d %H:%M:%S UTC')

    cleaned_orders['weekday'] = cleaned_orders['order_timestamp'].dt.strftime('%A')

    # Split and convert date
    cleaned_orders['date'] = pd.to_datetime(cleaned_orders['order_timestamp'], format='%Y-%m-%d').dt.date

    cleaned_orders = cleaned_orders.drop(['order_timestamp'], axis=1)

    # Round amount
    cleaned_orders['amount'] = round(cleaned_orders.amount, 2)

    # Convert cash or card
    cleaned_orders['paid_cash'] = np.where(cleaned_orders['paid_cash'], 'Cash', 'Card')

    ## Create pivot table for visualizations
    summarized_info = pd.pivot_table(
        cleaned_orders,
        index=['user_id', 'cuisine'],
        aggfunc={'order_id': 'count', 'amount': np.sum, 'date': pd.Series.nunique}
    ).rename(columns={'amount': 'total_amount', 'order_id': 'total_orders', 'date': 'frequency_of_orders_dates'})

    return cleaned_orders, summarized_info


if __name__ == '__main__':
    process_data('orders.csv')
