// server.js - Node.js Backend Server with PostgreSQL
// This handles authentication and data fetching for the CRM dashboard

const express = require('express');
const cors = require('cors');
const { Pool } = require('pg');
const crypto = require('crypto');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public')); // Serve static files (your HTML pages)

// PostgreSQL Connection Pool
const pool = new Pool({
    user: 'postgres',          // Change to your PostgreSQL username
    host: 'localhost',
    database: 'crm_dashboard', // Make sure this database exists
    password: '123456', // Change to your PostgreSQL password
    port: 5432,
});

// Test database connection
pool.connect((err, client, release) => {
    if (err) {
        console.error('Error connecting to PostgreSQL database:', err.stack);
    } else {
        console.log('✅ Connected to PostgreSQL database successfully!');
        release();
    }
});

// ====================================
// HELPER FUNCTIONS
// ====================================

// MD5 Hash function (for demo - use bcrypt in production)
function hashPassword(password) {
    return crypto.createHash('md5').update(password).digest('hex');
}

// ====================================
// API ENDPOINTS
// ====================================

// 1. USER LOGIN
app.post('/api/login', async (req, res) => {
    const { email, password } = req.body;

    try {
        const passwordHash = hashPassword(password);

        const query = `
            SELECT user_id, email, full_name, role, avatar_initials 
            FROM users 
            WHERE email = $1 AND password_hash = $2 AND is_active = TRUE
        `;

        const result = await pool.query(query, [email, passwordHash]);

        if (result.rows.length > 0) {
            const user = result.rows[0];

            // Update last login
            await pool.query(
                'UPDATE users SET last_login = CURRENT_TIMESTAMP WHERE user_id = $1',
                [user.user_id]
            );

            res.json({
                success: true,
                message: 'Login successful',
                user: {
                    id: user.user_id,
                    email: user.email,
                    name: user.full_name,
                    role: user.role,
                    initials: user.avatar_initials
                }
            });
        } else {
            res.status(401).json({
                success: false,
                message: 'Invalid email or password'
            });
        }
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error during login'
        });
    }
});

// 2. GET DASHBOARD STATS
app.get('/api/dashboard/stats', async (req, res) => {
    try {
        const query = `
            SELECT 
                (SELECT COALESCE(SUM(total_amount), 0) FROM orders WHERE status = 'completed') as total_revenue,
                (SELECT COUNT(*) FROM customers WHERE is_active = TRUE) as total_customers,
                (SELECT COUNT(*) FROM orders WHERE status IN ('pending', 'processing')) as active_orders,
                (SELECT ROUND(AVG(CASE WHEN status = 'completed' THEN 100 ELSE 0 END), 1) FROM orders) as satisfaction_rate
        `;

        const result = await pool.query(query);
        const stats = result.rows[0];

        // Calculate percentage changes (mock data for demo)
        res.json({
            success: true,
            stats: {
                revenue: {
                    value: parseFloat(stats.total_revenue).toFixed(2),
                    change: 12.5,
                    trend: 'up'
                },
                customers: {
                    value: parseInt(stats.total_customers),
                    change: 8.2,
                    trend: 'up'
                },
                orders: {
                    value: parseInt(stats.active_orders),
                    change: -3.1,
                    trend: 'down'
                },
                satisfaction: {
                    value: parseFloat(stats.satisfaction_rate).toFixed(1),
                    change: 2.4,
                    trend: 'up'
                }
            }
        });
    } catch (error) {
        console.error('Stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching dashboard stats'
        });
    }
});

// 3. GET REVENUE CHART DATA
app.get('/api/dashboard/revenue-chart', async (req, res) => {
    try {
        const query = `
            SELECT 
                TO_CHAR(date, 'Dy') as day,
                daily_revenue
            FROM revenue_stats 
            ORDER BY date ASC 
            LIMIT 7
        `;

        const result = await pool.query(query);

        const labels = result.rows.map(row => row.day);
        const data = result.rows.map(row => parseFloat(row.daily_revenue));

        res.json({
            success: true,
            chart: {
                labels: labels,
                data: data
            }
        });
    } catch (error) {
        console.error('Revenue chart error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching revenue chart data'
        });
    }
});

// 4. GET CATEGORY SALES DATA
app.get('/api/dashboard/category-chart', async (req, res) => {
    try {
        const query = `
            SELECT 
                p.category, 
                ROUND(SUM(oi.total_price)::numeric, 2) as total_sales
            FROM order_items oi
            JOIN products p ON oi.product_id = p.product_id
            JOIN orders o ON oi.order_id = o.order_id
            WHERE o.status = 'completed'
            GROUP BY p.category
            ORDER BY total_sales DESC
        `;

        const result = await pool.query(query);

        const labels = result.rows.map(row => row.category);
        const data = result.rows.map(row => parseFloat(row.total_sales));

        res.json({
            success: true,
            chart: {
                labels: labels,
                data: data
            }
        });
    } catch (error) {
        console.error('Category chart error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching category chart data'
        });
    }
});

// 5. GET RECENT ORDERS
app.get('/api/dashboard/recent-orders', async (req, res) => {
    try {

        const { status } = req.query;

        let query = `
            SELECT 
                o.order_number,
                TO_CHAR(o.order_date, 'Mon DD, YYYY') as order_date,
                o.total_amount,
                o.status,
                o.payment_status,
                c.first_name,
                c.last_name,
                c.email,
                c.avatar_initials
            FROM orders o
            JOIN customers c ON o.customer_id = c.customer_id
        `;

        const values = [];

        // Add WHERE clause only if status is provided and not 'all'
        if (status && status !== 'all') {
            values.push(status);
            query += ` WHERE o.status = $1 `;
        }

        query += `
            ORDER BY o.order_date DESC
            LIMIT 10
        `;

        const result = await pool.query(query, values);

        res.json({
            success: true,
            orders: result.rows
        });
    } catch (error) {
        console.error('Recent orders error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching recent orders'
        });
    }
});

// 6. GET ALL CUSTOMERS
app.get('/api/customers', async (req, res) => {
    try {
        const query = `
            SELECT 
                customer_id,
                first_name,
                last_name,
                email,
                phone,
                avatar_initials,
                total_orders,
                total_spent,
                TO_CHAR(created_at, 'Mon DD, YYYY') as joined_date
            FROM customers
            WHERE is_active = TRUE
            ORDER BY created_at DESC
        `;

        const result = await pool.query(query);

        res.json({
            success: true,
            customers: result.rows
        });
    } catch (error) {
        console.error('Customers error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching customers'
        });
    }
});

// 7. GET ALL PRODUCTS
app.get('/api/products', async (req, res) => {

    const { category } = req.query;


    try {
        // const query = `
        //     SELECT 
        //         product_id,
        //         product_name,
        //         category,
        //         price,
        //         stock_quantity,
        //         description
        //     FROM products
        //     WHERE is_active = TRUE
        //     ORDER BY product_name ASC
        // `;

        // const result = await pool.query(query);

        let query = `
             SELECT 
                product_id,
                product_name,
                category,
                price,
                stock_quantity,
                description
            FROM products
            WHERE is_active = TRUE
        `;

        const values = [];

        // Add WHERE clause only if status is provided and not 'all'
        if (category && category !== 'all') {
            values.push(category);
            query += ` AND category = $1 `;
        }

        query += `
            ORDER BY product_name ASC
        `;

        const result = await pool.query(query, values);


        res.json({
            success: true,
            products: result.rows
        });
    } catch (error) {
        console.error('Products error:', error);
        res.status(500).json({
            success: false,
            message: 'Error fetching products'
        });
    }
});

// ====================================
// START SERVER
// ====================================
app.listen(PORT, () => {
    console.log(`🚀 Server is running on http://localhost:${PORT}`);
    console.log(`📊 API available at http://localhost:${PORT}/api`);
    console.log(`\nAvailable endpoints:`);
    console.log(`  POST   /api/login`);
    console.log(`  GET    /api/dashboard/stats`);
    console.log(`  GET    /api/dashboard/revenue-chart`);
    console.log(`  GET    /api/dashboard/category-chart`);
    console.log(`  GET    /api/dashboard/recent-orders`);
    console.log(`  GET    /api/customers`);
    console.log(`  GET    /api/products`);
});

// Graceful shutdown
process.on('SIGINT', async () => {
    console.log('\n🛑 Shutting down gracefully...');
    await pool.end();
    process.exit(0);
});