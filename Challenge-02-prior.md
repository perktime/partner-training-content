# Challenge 02 - AI-Powered Search with Vector Embeddings

**[< Previous Challenge](./Challenge-01.md)** - **[Home](../README.md)** - **[Next Challenge >](./Challenge-03.md)**

## Introduction

Modern applications increasingly require intelligent search capabilities that go beyond simple text matching. In this challenge, you'll build AI-powered agents that can understand natural language queries and provide relevant responses using Azure Cosmos DB's vector search capabilities combined with traditional full-text search.

You'll work with a multi-agent banking application that demonstrates how to implement different types of search patterns: full-text search for exact matches, vector search for semantic similarity, and hybrid search that combines both approaches.

## Description

Building on your deployed banking application from Challenge 01, you'll now explore and extend its AI capabilities. The application includes multiple specialized agents (coordinator, customer support, transactions, and sales) that work together to handle different types of banking queries.

Your task is to understand how these agents use Azure Cosmos DB for different search scenarios and then implement your own enhancements to demonstrate vector search capabilities.

The agents are designed to:
- Handle natural language queries about banking services
- Transfer conversations between specialized agents based on context
- Perform vector searches on banking offers and product information
- Execute transactions while maintaining conversational context

### Analyze and Understand the AI Architecture

- **Vector Search Analysis:**
  - Identify which Azure Cosmos DB containers store vector embeddings
  - Understand how product offers are vectorized and searched
  - Explain the difference between exact text matching and semantic similarity search
  - Analyze how hybrid search combines vector and full-text search approaches for improved relevance

- **Agent Coordination:**
  - Document how the coordinator agent determines which specialized agent to route queries to
  - Explain how conversation context is maintained across agent transfers
  - Identify where conversation history is stored in Cosmos DB

- **Performance Monitoring:**
  - Monitor RU consumption during vector search operations
  - Compare RU costs between simple queries and vector similarity searches
  - Analyze query execution times for different search patterns

## Success Criteria

To complete this challenge successfully, you should:

- Identify and document which Cosmos DB containers store vector embeddings and explain how they are used for semantic search
- Document the agent coordination flow, explaining how queries are routed between specialized agents and how conversation context is maintained
- Monitor and record RU consumption for vector search operations compared to simple queries
- Analyze and compare query execution times across different search patterns (exact text matching vs. semantic similarity)
- Demonstrate understanding of hybrid search by explaining how it combines vector and full-text search for enhanced relevance

## Learning Resources

- [Vector Search in Azure Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/vector-search)
- [Azure OpenAI Embeddings](https://docs.microsoft.com/azure/cognitive-services/openai/concepts/embeddings)
- [Building Multi-Agent Systems](https://docs.microsoft.com/azure/cognitive-services/openai/concepts/advanced-usage)
- [Hybrid Search Patterns](https://docs.microsoft.com/azure/search/hybrid-search-overview)

## Tips

- Use the browser's developer tools to monitor network requests and understand the API calls
- Check the Azure portal's Cosmos DB Data Explorer to see how data is structured
- Pay attention to the different types of messages stored in the Chat and ChatHistory containers
- The Debug container contains useful information about agent decisions and search operations
- Vector searches typically consume more RUs than simple queries - monitor this in the portal
- Each agent has specialized prompts that determine their behavior and capabilities

## Advanced Challenges (Optional, time permitting)

- **Custom Vector Search:** Implement your own vector search functionality for a new type of banking product
- **Search Optimization:** Experiment with different similarity thresholds and measure their impact on search relevance
- **Hybrid Search Implementation:** Create a search function that combines both vector similarity and full-text search results, experimenting with different ranking and weighting strategies
- **Multi-modal Search:** Enhance the search to combine text vectors with other data types (dates, amounts, categories)
- **Performance Tuning:** Implement caching strategies for frequently accessed vectors to reduce RU consumption
- **Advanced Agents:** Create a new specialized agent that handles investment or insurance products

## Troubleshooting

- If the frontend doesn't start, ensure Node.js and Angular CLI are properly installed
- If the API returns errors, check that your Azure OpenAI service is running and has sufficient quota
- If vector searches aren't working, verify that the embedding model deployment is successful
- Monitor Azure costs during testing as AI services can accumulate charges quickly

**[< Previous Challenge](./Challenge-01.md)** - **[Home](../README.md)** - **[Next Challenge >](./Challenge-03.md)**
