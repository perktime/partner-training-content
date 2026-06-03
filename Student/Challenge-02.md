# Challenge 02 - AI-Powered Search with Vector Embeddings

**[< Previous Challenge](./Challenge-01.md)** - **[Home](../README.md)** - **[Next Challenge >](./Challenge-03.md)**

## Introduction

Modern applications increasingly require intelligent search capabilities that go beyond simple text matching.
This challenge demonstrates how to build AI-powered applications using Azure Cosmos DB's vector search capabilities. You will explore a multi-agent banking system that combines traditional queries with AI-powered semantic search.

In this challenge you will deploy both the FastAPI agent service (backend) and the Angular UI (frontend) as containers running in **Azure Container Instances (ACI)** so that the application is reachable on a public URL — no Codespace or local workstation required at runtime. If you'd prefer to iterate against the code locally, an optional local path is included at the end of this section.

## Deploy the application to Azure Container Instances

The provisioning step (run as part of Challenge 01) deploys an Azure Container Registry and a user-assigned managed identity in addition to Cosmos DB and Azure OpenAI. We will now:

1. Build the backend (Python/FastAPI) and frontend (Angular + nginx) container images directly in the ACR.
2. Deploy a single ACI **container group** that runs both containers behind one public IP. The frontend nginx reverse-proxies `/api` and `/tenant` calls to the backend over `localhost` (containers in the same group share the network namespace).
3. The container group is assigned the same user-assigned managed identity used everywhere else in the workshop, so the backend can authenticate to Cosmos DB and Azure OpenAI via `DefaultAzureCredential` with no secrets.

### 1. Make sure provisioning is complete

From the workshop root:

```bash
cd Student/Resources/banking-workshop
azd env select <your-env-name>   # only needed if you have multiple azd envs
azd provision                    # safe to re-run; no-op if already up to date
```

This must produce the following outputs (visible via `azd env get-values`):
`RG_NAME`, `ACR_NAME`, `ACR_LOGIN_SERVER`, `AZURE_IDENTITY_NAME`, `COSMOSDB_ENDPOINT`, `AZURE_OPENAI_ENDPOINT`, `AZURE_OPENAI_COMPLETIONSDEPLOYMENTID`, `AZURE_OPENAI_EMBEDDINGDEPLOYMENTID`.

### 2. Build the images and deploy the container group

```bash
cd Student/Resources/banking-workshop/infra
./deploy-app.sh
```

The script:

- Calls `az acr build` twice (once per Dockerfile) so the images are built inside Azure — no local Docker daemon needed.
- Deploys [`aci.bicep`](./Resources/banking-workshop/infra/aci.bicep), which creates a container group containing the `frontend` (port 80, public) and `backend` (port 8080, internal) containers and wires in the Cosmos DB / Azure OpenAI endpoints as environment variables.

When it finishes you will see something like:

```text
===== Banking app deployment summary =====
Public URL : http://banking-xxxxxxxx.eastus2.azurecontainer.io
FQDN       : banking-xxxxxxxx.eastus2.azurecontainer.io
==========================================
```

Open the **Public URL** in a browser. Allow 1–2 minutes after the deployment completes for both containers to start and pull their images. You can tail logs with:

```bash
az container logs \
  --resource-group $(azd env get-value RG_NAME) \
  --name $(az container list --resource-group $(azd env get-value RG_NAME) --query "[?starts_with(name,'ci-banking')].name | [0]" -o tsv) \
  --container-name backend \
  --follow
```

You should now be able to create a chat session, send messages, and receive completions from the agents.

![Final User Interface](./images/frontend.png)

<details markdown=1>
<summary markdown="span">Optional: run the app locally instead of on ACI</summary>

If you'd rather iterate against the code in a Codespace or on your workstation, you can run the same app locally. It will still talk to the Cosmos DB and Azure OpenAI resources you provisioned earlier.

> If you are using GitHub Codespaces, restart it if needed (in case it is inactive).

**Start the agent service**

```bash
cd Student/Resources/banking-workshop/backend

python -m venv .venv
source .venv/bin/activate
pip install -r src/app/requirements.txt
```

For Windows:

```bash
cd Student/Resources/banking-workshop/backend

python -m venv .venv
.venv\Scripts\activate
pip install -r src/app/requirements.txt
```

> If you are using PowerShell, activate the virtual environment with `.venv\Scripts\Activate.ps1`.

Start the FastAPI service:

```bash
uvicorn src.app.banking_agents_api_af:app --host 0.0.0.0 --port 63280
```

You should see:

```text
INFO:     Started server process [69449]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:63280 (Press CTRL+C to quit)
```

**Start the web application** — in a new terminal:

```bash
cd Student/Resources/banking-workshop/frontend
npm install
ng serve --proxy-config proxy.conf.json
```

Open `http://localhost:4200` in a browser.

</details>

## Start a conversation

Each agent is equipped with the ability to delegate tasks and transfer control to other relevant agents when needed.

In your browser, create a new conversation and try transferring money.

1. Type the following text:

```text
I want to transfer money
```

1. When prompted provide the amount and the accounts to transfer from and to.

```text
I want to transfer 500 from Acc001 to Acc003
```

1. When prompted, confirm the transaction (enter `Yes`).
1. The conversation should look similar to this.

![transfer](./images/transfer.png)

Navigate to the Azure Portal, and open the Azure Cosmos DB account. Open the `AccountsData` container and verify the transaction was successful.

Let's test a new scenario that will invoke a vector search for banking offers.

Return to the frontend in your browser and create a new conversation.

1. Type the following text to enquire about banking offers:

```text
Tell me about your banking offers
```

1. When transferred to the sales agent (which handles queries about product information) it will respond with a range of offers to choose from.

2. Type the following text:

```text
credit card
```

The conversation should look similar to this.

![offers](./images/offers.png)

## Bonus Activity: Test with Swagger

This solution is built as a backend that exposes API's called by the frontend. With the API layer ready, let's explore simple testing against our API layer in our application.

Open a new browser tab and navigate to <http://localhost:63280/docs> to view the swagger UI.

![Swagger UI](./images/swagger_ui.png)

This app comes with a few pre-created tenant and user ids that you can use to test with.

| Tenant Id | User Id  |
|-----------|----------|
| Contoso   | Mark     |
| Contoso   | Sandeep  |
| Contoso   | Theo     |
| Fabrikam  | Sajee    |
| Fabrikam  | Abhishek |
| Fabrikam  | David    |

We will demonstrate this doing manual testing using the Swagger UI with these operations below. To automate this, you'd take the URIs you see in Swagger and write REST API calls using a testing tool.

Create a new session with tenantId = `Contoso` and userId = `Mark`

![Create a new session](./images/post_create_session.png)

Click Execute.

Capture the value of the new sessionId

```json
{
  "id": "653cc488-e9d5-4af4-9175-9410e501acb9",
  "type": "session",
  "sessionId": "653cc488-e9d5-4af4-9175-9410e501acb9",
  "tenantId": "Contoso",
  "userId": "Mark",
  "tokensUsed": 0,
  "name": "Mark Brown",
  "messages": []
}
```

Next use the tenantId, userId, and the sessionId created above to say "Hello there!" to our agents.

![Create a new completion](./images/post_create_completion.png)

Fill in the values and click execute.

Here you can see the request from Swagger and the response from our agent.

```json
[
  {
    "id": "1a568dff-43fe-4477-977b-9c21c8bf61f3",
    "type": "ai_response",
    "sessionId": "653cc488-e9d5-4af4-9175-9410e501acb9",
    "tenantId": "Contoso",
    "userId": "Mark",
    "timeStamp": "",
    "sender": "User",
    "senderRole": "User",
    "text": "Hello there!",
    "debugLogId": "a7203518-51d3-4df8-aa43-7c041b553776",
    "tokensUsed": 0,
    "rating": true,
    "completionPromptId": ""
  },
  {
    "id": "10c6daa8-714d-41d8-b564-99a6c8ffdb5d",
    "type": "ai_response",
    "sessionId": "653cc488-e9d5-4af4-9175-9410e501acb9",
    "tenantId": "Contoso",
    "userId": "Mark",
    "timeStamp": "",
    "sender": "Coordinator",
    "senderRole": "Assistant",
    "text": "Hi there! Welcome to our bank. How can I assist you today? Are you looking for help with general inquiries, opening a new account or loan, or managing transactions? Let me know!",
    "debugLogId": "a7203518-51d3-4df8-aa43-7c041b553776",
    "tokensUsed": 265,
    "rating": true,
    "completionPromptId": ""
  }
]
```

## Success Criteria

To complete this challenge successfully, you should:

- Identify and document which Cosmos DB containers store vector embeddings and explain how they are used for semantic search
- Explore the agent coordination flow, explaining how queries are routed between specialized agents and how conversation context is maintained
- Monitor and record RU consumption for vector search operations compared to simple queries
- Analyze and compare query execution times across different search patterns (exact text matching vs. semantic similarity)

## Learning Resources

- [Vector Search in Azure Cosmos DB](https://docs.microsoft.com/azure/cosmos-db/vector-search)
- [Azure OpenAI Embeddings](https://docs.microsoft.com/azure/cognitive-services/openai/concepts/embeddings)
- [Building Multi-Agent Systems](https://docs.microsoft.com/azure/cognitive-services/openai/concepts/advanced-usage)
- [Hybrid Search Patterns](https://docs.microsoft.com/azure/search/hybrid-search-overview)

## Tips

- Use the browser's developer tools to monitor network requests and understand the API calls
- Check the Azure portal's Cosmos DB Data Explorer to see how data is structured
- Pay attention to the different types of messages stored in the `Chat` and `ChatHistory` containers
- The `Debug` container contains useful information about agent decisions and search operations
- Vector searches typically consume more RUs than simple queries - monitor this in the portal
- Each agent has specialized prompts that determine their behavior and capabilities


## Troubleshooting

- If the frontend doesn't start, ensure Node.js and Angular CLI are properly installed
- If the API returns errors, check that your Azure OpenAI service is running and has sufficient quota
- If vector searches aren't working, verify that the embedding model deployment is successful
- Monitor Azure costs during testing as AI services can accumulate charges quickly

## Advanced Challenges (Optional, time permitting)

- **Custom Vector Search:** Implement your own vector search functionality for a new type of banking product
- **Search Optimization:** Experiment with different similarity thresholds and measure their impact on search relevance
- **Hybrid Search Implementation:** Create a search function that combines both vector similarity and full-text search results, experimenting with different ranking and weighting strategies
- **Multi-modal Search:** Enhance the search to combine text vectors with other data types (dates, amounts, categories)
- **Performance Tuning:** Implement caching strategies for frequently accessed vectors to reduce RU consumption
- **Advanced Agents:** Create a new specialized agent that handles investment or insurance products

**[< Previous Challenge](./Challenge-01.md)** - **[Home](../README.md)** - **[Next Challenge >](./Challenge-03.md)**
