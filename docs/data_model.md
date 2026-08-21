# Data Model

## customers

Primary Key

customer_id

Contains customer demographic and location information.

---

## orders

Primary Key

order_id

Foreign Key

customer_id

Stores order lifecycle information.

---

## order_items

Primary Key

order_id + order_item_id

Foreign Key

order_id

product_id

seller_id

Stores purchased products.

---

# Table Relationships

| Parent | Child | Relationship | Description |
|---------|---------|--------------|-------------|
| Customers | Orders | 1:N | One customer can place multiple orders. |
| Orders | Order Items | 1:N | One order can contain multiple products. |
| Products | Order Items | 1:N | One product can appear in many orders. |
| Sellers | Order Items | 1:N | One seller can sell many products. |
| Orders | Payments | 1:N | One order may have multiple payment records. |
| Orders | Reviews | 1:1 | One order can receive one review. |
| Product Category Translation | Products | 1:N | One category can be assigned to many products. |

# Business Process

Customer

↓

Create Order

↓

Payment

↓

Seller ships

↓

Delivered

↓

Customer Review