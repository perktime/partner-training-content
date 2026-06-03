# Minimal LangChain dependencies for gradual migration
# Only keep what's actually needed by remaining LangChain files

# Agent Framework (primary)
agent-framework-azure-ai
agent-framework-core

# Minimal LangChain for remaining files
langchain-core==0.3.33
langchain-openai==0.3.3
langgraph==0.2.69
langgraph-checkpoint==2.0.10
langgraph_checkpoint_cosmosdb==0.2.3

# Remove these unused LangChain packages:
# langchain==0.3.17 (main package not needed)
# langchain-text-splitters==0.3.5 (not used)
# langgraph-sdk==0.1.51 (not needed for core functionality) 
# langsmith==0.3.1 (not needed)