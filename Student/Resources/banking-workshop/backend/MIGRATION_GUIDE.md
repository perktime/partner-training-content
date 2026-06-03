# LangGraph to Microsoft Agent Framework Migration Guide

## Migration Overview

This document outlines the migration of the banking application from LangGraph to Microsoft Agent Framework.

## Current LangGraph Architecture

### Components
- **StateGraph with MessagesState**: Manages conversation state
- **create_react_agent**: Creates reactive agents with tools
- **Command-based routing**: Manual routing between agents
- **CosmosDBSaver**: Checkpoint storage for conversation persistence
- **Human interrupt nodes**: Manual user input collection

### Agent Structure
```python
# Current LangGraph pattern
coordinator_agent = create_react_agent(
    model,
    tools=coordinator_agent_tools,
    state_modifier=load_prompt("coordinator_agent"),
)

builder = StateGraph(MessagesState)
builder.add_node("coordinator_agent", call_coordinator_agent)
builder.add_edge(START, "coordinator_agent")
graph = builder.compile(checkpointer=checkpointer)
```

## Target Agent Framework Architecture

### Components
- **WorkflowBuilder with Executors**: Workflow orchestration
- **ChatAgent with AzureAIAgentClient**: AI-powered agents
- **HandoffBuilder**: Multi-agent coordination patterns
- **CheckpointStorage**: Built-in conversation persistence
- **Automatic conversation management**: Streamlined user interactions

### Agent Structure
```python
# Target Agent Framework pattern
class BankingAgentExecutor(Executor):
    def __init__(self, chat_client, agent_name, instructions, tools):
        self.agent = chat_client.create_agent(
            instructions=instructions,
            tools=tools
        )
        super().__init__(id=agent_name)
    
    @handler
    async def handle_message(self, message: ChatMessage, ctx: WorkflowContext) -> None:
        response = await self.agent.run([message])
        await ctx.yield_output(response.text)

# HandoffBuilder workflow
workflow = (
    HandoffBuilder(
        name="banking_workflow",
        participants=[coordinator, sales, support, transactions]
    )
    .set_coordinator(coordinator)
    .add_handoff(coordinator, [sales, support, transactions])
    .build()
)
```

## Migration Steps

### Step 1: Environment Setup ✅
- Install Agent Framework packages
- Update requirements.txt with agent-framework-azure-ai
- Configure Azure AI Foundry credentials

### Step 2: Agent Creation Migration
**From:**
```python
coordinator_agent = create_react_agent(
    model, tools, state_modifier=prompt
)
```

**To:**
```python
class CoordinatorExecutor(Executor):
    def __init__(self, chat_client):
        self.agent = chat_client.create_agent(
            instructions=prompt,
            tools=tools
        )
        super().__init__(id="coordinator")
```

### Step 3: Workflow Migration
**From:**
```python
builder = StateGraph(MessagesState)
builder.add_node("coordinator_agent", call_coordinator_agent)
builder.add_edge(START, "coordinator_agent")
```

**To:**
```python
workflow = (
    HandoffBuilder(participants=[coordinator, sales, support, transactions])
    .set_coordinator(coordinator)
    .add_handoff(coordinator, [sales, support, transactions])
    .build()
)
```

### Step 4: Execution Migration
**From:**
```python
for update in graph.stream(input_message, config=thread_config):
    for node_id, value in update.items():
        if isinstance(value, dict) and value.get("messages"):
            last_message = value["messages"][-1]
            print(f"{node_id}: {last_message.content}")
```

**To:**
```python
async for event in workflow.run_stream(user_message):
    if isinstance(event, WorkflowOutputEvent):
        print(f"Assistant: {event.data}")
```

## Key Benefits of Migration

### 1. Simplified Architecture
- **Automatic handoff detection**: No manual Command routing
- **Built-in conversation management**: No manual state handling
- **Streamlined tool integration**: Direct tool attachment to agents

### 2. Better Azure Integration
- **Native Azure AI Foundry support**: Direct integration with Azure models
- **Azure authentication**: Seamless credential management
- **Azure monitoring**: Built-in telemetry and observability

### 3. Reduced Boilerplate
- **Less manual coordination code**: HandoffBuilder handles routing
- **Automatic conversation history**: No manual message management
- **Simplified error handling**: Built-in error handling patterns

## Configuration Requirements

### Azure AI Foundry Setup
```bash
# Environment variables needed
export AZURE_AI_FOUNDRY_ENDPOINT="https://your-project.ai.azure.com"
export AZURE_AI_FOUNDRY_MODEL="gpt-4o"
```

### Agent Framework Client
```python
from agent_framework_azure_ai import AzureAIAgentClient
from azure.identity import DefaultAzureCredential

chat_client = AzureAIAgentClient(
    project_endpoint=ENDPOINT,
    model_deployment_name=MODEL_DEPLOYMENT_NAME,
    credential=DefaultAzureCredential()
)
```

## Migration Timeline

- [x] **Phase 1**: Install Agent Framework and create demo
- [ ] **Phase 2**: Implement HandoffBuilder workflow
- [ ] **Phase 3**: Migrate Cosmos DB checkpointing
- [ ] **Phase 4**: Full testing and validation
- [ ] **Phase 5**: Replace original LangGraph implementation

## Testing Strategy

1. **Side-by-side comparison**: Run both implementations in parallel
2. **Agent-by-agent migration**: Migrate one agent at a time
3. **Conversation validation**: Ensure conversation flows match
4. **Performance testing**: Compare response times and resource usage
5. **Integration testing**: Verify tool calls and Cosmos DB operations

## Considerations

### Azure AI Foundry Requirement
- Agent Framework requires Azure AI Foundry project
- Need to configure model deployment
- Requires appropriate Azure subscription and permissions

### Tool Migration
- Tools need to be compatible with Agent Framework patterns
- May require wrapper functions for complex tools
- Ensure async compatibility

### Cosmos DB Integration
- Need to implement custom CheckpointStorage for Cosmos DB
- Migrate existing conversation data
- Ensure checkpoint compatibility

## Next Steps

1. Set up Azure AI Foundry project
2. Implement working HandoffBuilder example
3. Create custom Cosmos DB CheckpointStorage
4. Migrate and test each banking agent
5. Validate complete workflow functionality

## Files Changed

- `requirements.txt`: Added Agent Framework packages
- `banking_agents_af.py`: New Agent Framework implementation
- `MIGRATION_GUIDE.md`: This documentation

## Resources

- [Microsoft Agent Framework GitHub](https://github.com/microsoft/agent-framework)
- [Azure AI Foundry Documentation](https://docs.microsoft.com/azure/ai-foundry/)
- [Agent Framework Python SDK](https://pypi.org/project/agent-framework-azure-ai/)