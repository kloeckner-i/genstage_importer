#!/usr/bin/env ruby

PRODUCT_SUMMARY_HEADER = "PRODUCT_NUMBER|PRICE|COMMODITY|SHORT_DESC\n".freeze
PRODUCT_SUMMARY_ROW = "$product_number$|$price$|$commodity$|$description$\n".freeze

commodities = %w[Plate Coil Tube]
products = []

File.open('./files/products.csv', 'w') do |f|
  f.write(PRODUCT_SUMMARY_HEADER)
  500_000.times do |i|
    product_number = "product-#{i}"
    f.write(
      PRODUCT_SUMMARY_ROW
        .gsub('$product_number$', product_number)
        .gsub('$price$', (Random.rand * 1000.0).to_s)
        .gsub('$commodity$', commodities[Random.rand(3)])
        .gsub('$description$', "description-#{i}")
    )
    products << product_number
  end
end

products.shuffle!

ORDERS_HEADER = "ORDER_NUMBER|LINE_STATUS|PRODUCT_NUMBER|ORDERED_PIECES|SHIPPED_PIECES|BILL_OF_LADING\n".freeze
ORDERS_ROW = "$order_number$|$line_status$|$product_number$|$ordered$|$shipped$|$bill_of_lading$\n".freeze

File.open('./files/orders.csv', 'w') do |f|
  f.write(ORDERS_HEADER)

  products.each_with_index do |product, index|
    orders = [
      # fully shipped
      {
        order_number: "order-#{index * 5}",
        line_status: 'Closed',
        ordered: 1234,
        shipped: 1234,
        bill_of_lading: 'bill-number'
      },
      # ignored
      {
        order_number: "order-#{index * 5 + 1}",
        line_status: 'Closed',
        ordered: 1,
        shipped: 0,
        bill_of_lading: ''
      },
      # partially shipped, 2 shipments
      {
        order_number: "order-#{index * 5 + 2}",
        line_status: 'Closed',
        ordered: 4000,
        shipped: 1200,
        bill_of_lading: '12'
      },
      {
        order_number: "order-#{index * 5 + 2}",
        line_status: 'Open',
        ordered: 4000,
        shipped: 2000,
        bill_of_lading: ''
      },
      # fully shipped, 2 shipments
      {
        order_number: "order-#{index * 5 + 3}",
        line_status: 'Closed',
        ordered: 4000,
        shipped: 1200,
        bill_of_lading: '1235'
      },
      {
        order_number: "order-#{index * 5 + 3}",
        line_status: 'Closed',
        ordered: 4000,
        shipped: 2800,
        bill_of_lading: '344'
      },
      # partially shipped, but nothing is pending
      {
        order_number: "order-#{index * 5 + 4}",
        line_status: 'Open',
        ordered: 4000,
        shipped: 1000,
        bill_of_lading: '543543543'
      },
      {
        order_number: "order-#{index * 5 + 4}",
        line_status: 'Closed',
        ordered: 4000,
        shipped: 2800,
        bill_of_lading: '543543'
      }
    ]

    orders.each do |order|
      f.write(
        ORDERS_ROW
          .gsub('$order_number$', order[:order_number])
          .gsub('$line_status$', order[:line_status])
          .gsub('$product_number$', product)
          .gsub('$ordered$', order[:ordered].to_s)
          .gsub('$shipped$', order[:shipped].to_s)
          .gsub('$bill_of_lading$', order[:bill_of_lading])
      )
    end
  end
end
