-- CRM Database Schema for PostgreSQL
-- Run this script in pgAdmin to create all necessary tables

-- ====================================
-- 1. CREATE DATABASE
-- ====================================
-- First, create the database (run this separately in pgAdmin)
-- CREATE DATABASE crm_dashboard;

-- ====================================
-- 2. USERS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS users (
    user_id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'user',
    avatar_initials VARCHAR(5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- ====================================
-- 3. CUSTOMERS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    avatar_initials VARCHAR(5),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_orders INTEGER DEFAULT 0,
    total_spent DECIMAL(10, 2) DEFAULT 0.00,
    is_active BOOLEAN DEFAULT TRUE
);

-- ====================================
-- 4. ORDERS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS orders (
    order_id SERIAL PRIMARY KEY,
    order_number VARCHAR(50) UNIQUE NOT NULL,
    customer_id INTEGER REFERENCES customers(customer_id) ON DELETE CASCADE,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(50) DEFAULT 'pending',
    -- status can be: 'pending', 'completed', 'cancelled', 'processing'
    payment_status VARCHAR(50) DEFAULT 'unpaid',
    -- payment_status can be: 'paid', 'unpaid', 'refunded'
    shipping_address TEXT,
    notes TEXT
);

-- ====================================
-- 5. PRODUCTS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS products (
    product_id SERIAL PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(100) NOT NULL,
    -- category can be: 'Electronics', 'Clothing', 'Food', 'Books', 'Other'
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN DEFAULT TRUE
);

-- ====================================
-- 6. ORDER ITEMS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER REFERENCES orders(order_id) ON DELETE CASCADE,
    product_id INTEGER REFERENCES products(product_id) ON DELETE SET NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10, 2) NOT NULL,
    total_price DECIMAL(10, 2) NOT NULL
);

-- ====================================
-- 7. REVENUE STATS TABLE
-- ====================================
CREATE TABLE IF NOT EXISTS revenue_stats (
    stat_id SERIAL PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    daily_revenue DECIMAL(10, 2) DEFAULT 0.00,
    total_orders INTEGER DEFAULT 0,
    new_customers INTEGER DEFAULT 0
);

-- ====================================
-- INDEXES FOR PERFORMANCE
-- ====================================
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order_id ON order_items(order_id);
CREATE INDEX idx_order_items_product_id ON order_items(product_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_revenue_stats_date ON revenue_stats(date);

-- ====================================
-- INSERT SAMPLE DATA
-- ====================================

-- Insert Admin User (password is hashed version of '12345')
-- Note: In production, use bcrypt. This is MD5 for demo purposes
INSERT INTO users (email, password_hash, full_name, role, avatar_initials) VALUES
('user@admin.com', '827ccb0eea8a706c4c34a16891f84e7b', 'Admin User', 'administrator', 'UA'),
('john@example.com', '827ccb0eea8a706c4c34a16891f84e7b', 'John Smith', 'user', 'JS');

-- Insert Sample Customers
INSERT INTO customers (first_name, last_name, email, phone, avatar_initials, total_orders, total_spent) VALUES
('John', 'Doe', 'john@example.com', '+1-555-0101', 'JD', 5, 2145.50),
('Sarah', 'Miller', 'sarah@example.com', '+1-555-0102', 'SM', 3, 1234.00),
('Robert', 'Johnson', 'robert@example.com', '+1-555-0103', 'RJ', 8, 3456.75),
('Emily', 'Davis', 'emily@example.com', '+1-555-0104', 'ED', 2, 456.20),
('Michael', 'Wilson', 'michael@example.com', '+1-555-0105', 'MW', 6, 2892.40),
('Jessica', 'Brown', 'jessica@example.com', '+1-555-0106', 'JB', 4, 1678.90),
('David', 'Taylor', 'david@example.com', '+1-555-0107', 'DT', 7, 3123.60),
('Lisa', 'Anderson', 'lisa@example.com', '+1-555-0108', 'LA', 3, 987.30);

-- Insert Sample Products
INSERT INTO products (product_name, category, price, stock_quantity, description) VALUES
('Wireless Headphones', 'Electronics', 149.99, 50, 'Premium wireless headphones with noise cancellation'),
('Laptop Stand', 'Electronics', 79.99, 100, 'Ergonomic aluminum laptop stand'),
('Smart Watch', 'Electronics', 299.99, 30, 'Fitness tracking smart watch'),
('Designer T-Shirt', 'Clothing', 45.50, 200, 'Premium cotton designer t-shirt'),
('Jeans', 'Clothing', 89.99, 150, 'Classic fit denim jeans'),
('Winter Jacket', 'Clothing', 199.99, 75, 'Warm winter jacket with hood'),
('Organic Coffee Beans', 'Food', 24.99, 500, 'Premium organic coffee beans 1kg'),
('Chocolate Box', 'Food', 34.50, 300, 'Assorted premium chocolates'),
('Programming Book', 'Books', 59.99, 120, 'Complete guide to modern programming'),
('Novel - Best Seller', 'Books', 19.99, 200, 'Latest bestselling novel'),
('Desk Lamp', 'Other', 45.00, 80, 'LED desk lamp with adjustable brightness'),
('Phone Case', 'Electronics', 29.99, 250, 'Protective phone case');

-- Insert Sample Orders
INSERT INTO orders (order_number, customer_id, order_date, total_amount, status, payment_status) VALUES
('#12345', 1, '2026-02-08 10:30:00', 432.50, 'completed', 'paid'),
('#12346', 2, '2026-02-08 14:15:00', 789.00, 'pending', 'unpaid'),
('#12347', 3, '2026-02-07 09:20:00', 234.75, 'completed', 'paid'),
('#12348', 4, '2026-02-07 16:45:00', 156.20, 'cancelled', 'refunded'),
('#12349', 5, '2026-02-06 11:00:00', 892.40, 'completed', 'paid'),
('#12350', 6, '2026-02-06 13:30:00', 345.80, 'processing', 'paid'),
('#12351', 7, '2026-02-05 15:10:00', 567.90, 'completed', 'paid'),
('#12352', 8, '2026-02-05 10:25:00', 223.40, 'completed', 'paid'),
('#12353', 1, '2026-02-04 12:00:00', 678.30, 'completed', 'paid'),
('#12354', 3, '2026-02-04 14:50:00', 445.60, 'completed', 'paid');

-- Insert Sample Order Items
INSERT INTO order_items (order_id, product_id, quantity, unit_price, total_price) VALUES
(1, 1, 2, 149.99, 299.98),
(1, 7, 1, 24.99, 24.99),
(1, 11, 1, 45.00, 45.00),
(2, 3, 1, 299.99, 299.99),
(2, 4, 3, 45.50, 136.50),
(3, 7, 5, 24.99, 124.95),
(3, 10, 2, 19.99, 39.98),
(4, 12, 3, 29.99, 89.97),
(5, 6, 2, 199.99, 399.98),
(5, 9, 1, 59.99, 59.99);

-- Insert Revenue Stats for the last 7 days
INSERT INTO revenue_stats (date, daily_revenue, total_orders, new_customers) VALUES
('2026-02-09', 7500.00, 42, 8),
('2026-02-08', 6800.00, 38, 6),
('2026-02-07', 7200.00, 45, 7),
('2026-02-06', 6300.00, 35, 5),
('2026-02-05', 4800.00, 28, 4),
('2026-02-04', 5100.00, 30, 3),
('2026-02-03', 4200.00, 25, 2);

-- ====================================
-- USEFUL QUERIES
-- ====================================

-- Query 1: User Login Verification
-- SELECT user_id, email, full_name, role, avatar_initials 
-- FROM users 
-- WHERE email = 'user@admin.com' AND password_hash = MD5('12345') AND is_active = TRUE;

-- Query 2: Dashboard Stats
-- SELECT 
--     (SELECT SUM(total_amount) FROM orders WHERE status = 'completed') as total_revenue,
--     (SELECT COUNT(*) FROM customers WHERE is_active = TRUE) as total_customers,
--     (SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'processing')) as active_orders,
--     (SELECT ROUND(AVG(CASE WHEN status = 'completed' THEN 100 ELSE 0 END), 1) FROM orders) as satisfaction_rate;

-- Query 3: Revenue Chart Data (Last 7 Days)
-- SELECT date, daily_revenue 
-- FROM revenue_stats 
-- ORDER BY date DESC 
-- LIMIT 7;

-- Query 4: Sales by Category
-- SELECT p.category, SUM(oi.total_price) as total_sales, COUNT(DISTINCT oi.order_id) as order_count
-- FROM order_items oi
-- JOIN products p ON oi.product_id = p.product_id
-- JOIN orders o ON oi.order_id = o.order_id
-- WHERE o.status = 'completed'
-- GROUP BY p.category
-- ORDER BY total_sales DESC;

-- Query 5: Recent Orders for Dashboard Table
-- SELECT 
--     o.order_number,
--     o.order_date,
--     o.total_amount,
--     o.status,
--     c.first_name,
--     c.last_name,
--     c.email,
--     c.avatar_initials
-- FROM orders o
-- JOIN customers c ON o.customer_id = c.customer_id
-- ORDER BY o.order_date DESC
-- LIMIT 10;

-- Query 6: Update Customer Totals (Trigger alternative)
-- UPDATE customers c
-- SET 
--     total_orders = (SELECT COUNT(*) FROM orders WHERE customer_id = c.customer_id),
--     total_spent = (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE customer_id = c.customer_id AND status = 'completed')
-- WHERE c.customer_id = 1;

COMMIT;
