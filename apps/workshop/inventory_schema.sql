-- Original schema version 1. Only this project's two tables are owned by the app.
IF OBJECT_ID('dbo.workshop_items', 'U') IS NULL
  CREATE TABLE dbo.workshop_items (
    sku VARCHAR(64) NOT NULL PRIMARY KEY,
    stock INT NOT NULL CHECK(stock >= 0)
  );
IF OBJECT_ID('dbo.workshop_orders', 'U') IS NULL
  CREATE TABLE dbo.workshop_orders (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    sku VARCHAR(64) NOT NULL REFERENCES dbo.workshop_items(sku),
    quantity INT NOT NULL CHECK(quantity > 0)
  );
