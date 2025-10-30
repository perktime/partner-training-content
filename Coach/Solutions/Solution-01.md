# Challenge 01 - Data Modeling & Query Optimization - Coach's Guide

**[< Previous Challenge](./Solution-00.md)** - **[Home](../../README.md)** - **[Next Challenge >](./Solution-02.md)**

## Solution Overview

This challenge teaches fundamental Cosmos DB concepts through hands-on experimentation with different partition key strategies and indexing policies. Teams will learn by measuring actual RU consumption and performance differences.

## Learning Objectives for Students

- Understand how partition key choice affects query performance and cost
- Learn the difference between hot and distributed partitions
- Experience the impact of indexing policies on RU consumption
- Practice NoSQL data modeling principles
- Develop skills in performance analysis and optimization

## Pre-Challenge Setup for Coaches

### Sample Data Files
Ensure teams have access to sample e-commerce data files:
- `customers.json` - Customer records
- `products.json` - Product catalog
- `categories.json` - Product categories
- `tags.json` - Product tags
- `orders.json` - Sales order data

### Expected Container Configurations

#### Container A: customers
- **Purpose:** Store customer and sales order data together
- **Partition Key Options:**
  1. `/id` - Each document gets its own partition
  2. `/customerId` - Customer and their orders share partitions

#### Container B: products  
- **Purpose:** Store product catalog data
- **Partition Key Options:**
  1. `/categoryId` - Products grouped by category
  2. `/id` - Each product gets its own partition

#### Container C: productMeta
- **Purpose:** Store categories and tags
- **Partition Key:** `/type` - Groups by document type

## Detailed Solution Guide

### Part 1: Container Design Experiments

#### Experiment A: Customers & Sales Orders

**Option 1: Partition Key = `/id`**
```json
// Expected behavior:
// - Point reads are very efficient (1-2 RUs)
// - Cross-partition queries for customer orders are expensive (10+ RUs)
// - Good partition distribution but poor query performance
```

**Option 2: Partition Key = `/customerId`**
```json
// Expected behavior:
// - Point reads by customer ID are efficient (2-3 RUs)
// - Customer order queries are very efficient (3-5 RUs)
// - Better query performance but potential hot partitions for active customers
```

**Coaching Points:**
- Show teams how to view RU consumption in Data Explorer
- Explain that `/customerId` is better for this access pattern
- Discuss hot partition risks with high-volume customers

#### Experiment B: Products

**Option 1: Partition Key = `/categoryId`**
```json
// Expected behavior:
// - Category browsing queries are very efficient (3-5 RUs)
// - Point reads by product ID require cross-partition query (5-10 RUs)
// - Good for e-commerce browsing patterns
```

**Option 2: Partition Key = `/id`**
```json
// Expected behavior:
// - Point reads by product ID are very efficient (1-2 RUs)
// - Category browsing requires cross-partition query (15+ RUs)
// - Good for direct product access, poor for browsing
```

**Coaching Points:**
- Help teams understand the access pattern trade-offs
- Explain when each approach is appropriate
- Show how query patterns drive partition key decisions

#### Experiment C: Product Metadata

**Partition Key = `/type`**
```json
// Expected behavior:
// - Listing all categories is efficient (2-4 RUs)
// - Listing all tags is efficient (2-4 RUs)
// - Simple queries with good partition alignment
```

**Coaching Points:**
- Demonstrate how low-cardinality partition keys work
- Explain when this pattern is appropriate
- Show the efficiency of aligned queries

### Part 2: Indexing Policy Experiments

#### Default Indexing Policy
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/*"
    }
  ],
  "excludedPaths": [
    {
      "path": "/\"_etag\"/?"}
  ]
}
```

#### Optimized Indexing Policy Example
```json
{
  "indexingMode": "consistent",
  "automatic": true,
  "includedPaths": [
    {
      "path": "/customerId/?"
    },
    {
      "path": "/categoryId/?"
    },
    {
      "path": "/price/?"
    }
  ],
  "excludedPaths": [
    {
      "path": "/*"
    },
    {
      "path": "/description/?"
    },
    {
      "path": "/largeData/?"
    }
  ]
}
```

**Expected Results:**
- Queries using indexed properties: Lower RU consumption
- Queries using excluded properties: Higher RU consumption or failures
- Write operations: Slightly lower RU consumption with selective indexing

### Part 3: Query Pattern Analysis

#### Sample Queries and Expected RU Consumption

**Point Read (Best Case)**
```sql
SELECT * FROM c WHERE c.id = \"CUST001\" AND c.customerId = \"CUST001\"
-- Expected: 1-2 RUs (includes partition key)
```

**Range Query (Good Case)**
```sql
SELECT * FROM c WHERE c.customerId = \"CUST001\" AND c.type = \"salesOrder\"
-- Expected: 3-5 RUs (within partition)
```

**Cross-Partition Query (Expensive)**
```sql
SELECT * FROM c WHERE c.category = \"Electronics\"
-- Expected: 10-50+ RUs (depends on data size)
```

**Aggregation Query (Most Expensive)**
```sql
SELECT c.customerId, COUNT(1) as orderCount FROM c WHERE c.type = \"salesOrder\" GROUP BY c.customerId
-- Expected: 20-100+ RUs (cross-partition aggregation)
```

## Common Coaching Challenges

### 1. Students Don't Understand RU Consumption
**Problem:** Teams focus only on query results, not performance metrics
**Solutions:**
- Always show the \"Request Charge\" in Data Explorer
- Explain that RUs directly translate to cost
- Create a cost comparison table during experiments

### 2. Confusion About Partition Keys
**Problem:** Teams try to use relational database thinking
**Solutions:**
- Emphasize \"query-driven design\"
- Show concrete examples of hot vs cold partitions
- Explain that denormalization is normal in NoSQL

### 3. Indexing Policy Complexity
**Problem:** Teams get overwhelmed by indexing options
**Solutions:**
- Start with simple include/exclude examples
- Show the impact on write performance
- Focus on commonly queried properties

### 4. Not Seeing Performance Differences
**Problem:** With small datasets, differences aren't obvious
**Solutions:**
- Use bulk operations to amplify differences
- Explain how patterns scale with data volume
- Show theoretical scaling examples

## Expected Results Summary

| Container | Partition Key | Query Type | Expected RU | Notes |
|-----------|---------------|------------|-------------|--------|
| customers | /id | Point Read | 1-2 RUs | Efficient |
| customers | /id | Customer Orders | 10-20 RUs | Cross-partition |
| customers | /customerId | Point Read | 2-3 RUs | Good |
| customers | /customerId | Customer Orders | 3-5 RUs | Very efficient |
| products | /categoryId | Category Browse | 3-5 RUs | Excellent |
| products | /categoryId | Product Detail | 5-10 RUs | Cross-partition |
| products | /id | Product Detail | 1-2 RUs | Excellent |
| products | /id | Category Browse | 15-30 RUs | Cross-partition |
| productMeta | /type | List Categories | 2-4 RUs | Efficient |
| productMeta | /type | List Tags | 2-4 RUs | Efficient |

## Time Management

- **Total Duration:** 90-120 minutes
- **Setup:** 15 minutes
- **Experiments:** 60 minutes
- **Analysis:** 30 minutes
- **Discussion:** 15 minutes

## Key Teaching Moments

### 1. Partition Key Selection Strategy
- Always start with query patterns
- Consider data distribution and hotspots
- Think about scale and growth patterns

### 2. NoSQL vs SQL Mindset Shift
- Denormalization is normal and beneficial
- Optimize for reads, not writes
- Accept some data duplication for performance

### 3. Cost vs Performance Trade-offs
- Show actual cost implications of different designs
- Explain operational vs capital expenses
- Discuss business impact of query performance

## Advanced Topics (if time permits)

### Hierarchical Partition Keys
- Explain multi-level partitioning
- Show examples: `/tenantId/customerId`
- Discuss when to use composite keys

### Analytical Store
- Compare OLTP vs OLAP query patterns
- Show when to use analytical store
- Explain cost implications

### Change Feed
- Demonstrate real-time data processing
- Show integration patterns
- Explain scaling considerations

## Success Validation

Teams successfully complete when they can:
1. ✅ Explain why different partition keys perform differently
2. ✅ Show measured RU differences between query patterns
3. ✅ Identify which partition key is best for each scenario
4. ✅ Understand the impact of indexing on performance and cost
5. ✅ Articulate when to use cross-partition queries
6. ✅ Apply NoSQL modeling principles to new scenarios

## Preparation for Next Challenge

Before moving to Challenge 02:
- Ensure teams understand vector search concepts
- Explain how AI workloads differ from traditional queries
- Preview how embeddings work with partition keys
- Set expectations for Challenge 03 complexity
