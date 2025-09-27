# Enterprise Service Bus (ESB) implementation on InterSystems IRIS Data Platform
I was surprised that a platform with such a rich integration toolset has no ready-to-use ESB solution. This project is a try to implement some typical ESB features:
1. Centralize integration code on one platform
2. Message management (message broker) with guaranteed delivery based on Pub/Sub architecture
3. Message validation
4. Universal API to receive any message types (using payload container)
5. Centralized monitoring and alerting control

This project contains 3 main modules, let us take a look at them.
## Message Broker
Message Broker is designed to keep messages and create separate message consumers, each of which can be independently subscribed to a message queue. It means all consumers have their own inbound queue by message type. Messages have statuses: `NEW`, `PENDING` (processing in progress), `ERROR`, and `OK` (message successfully processed). The main purpose of the Message Broker is to guarantee delivery. The message will be resending again and again until one of two events happens: successful message processing or the end of message lifetime (message expired).

Here uses a bit improved version of the Kafka algorithm. Kafka keeps the offset of the last processed message for moving forward on the message queue. In IRIS ESB, we keep all processed message IDs, which allows us not to stop consuming when we have some "troubled" messages in the queue. 

I have not used an external broker, as the same Kafka, for not to lose the coolest IRIS feature - possible to see all that happens with the messages in visual traces. I believe one of the most important features of the ESB design pattern it's message guarantee delivery (based on retries), and possible to restore data flows after the temporary unavailability of external systems without manual actions. Kafka has no these features also.
### How to add data flow in Message Broker? 

First of all, your Production must have a `Broker.Process.MessageRouter` business host. He is responsible for routing messages to handlers and setting message statuses. Just add `MessageRouter` to Production, no need for any additional settings here. It will be common for all data flows.

Next, you need a handler for the message that extends `Broker.Process.MessageHandler`. It is a place for your custom code for message processing: mapping and transforming to other message types, sending to external systems via business operations, and so on.   

Finally, create a consumer. It is a business service instance of `Broker.Service.InboxReader` class. Where:

- `MessageHandler` - you hadler from the previous section
- `MessageType` - on what kind of message we wanna subscribe? It is a full analogy topic on Kafka
- `MessageLifetime` - when the message will expire? Can be different for each customer
## Inbox REST API
Each ESB should have a universal way to receive messages from external systems. Here it's a REST API. Universal means you can send any JSON payload to this API. The received JSON text will be deserialized into the Cache class and placed in the Inbox queue. IRIS ESB works with class objects, not `%DynamicObject`, for example, becouse validation of messages is one more important feature of the ESB pattern.

So, to add a new custom message type, you need to create a class (or import from some schema) that extends `Inbox.Message.Inbound` describes the structure of your message (see samples in `Sample.Message.*` package). When you send a message to the Inbox API, set the name of this class as the `import_to` parameter. Also, you should use the same class name for creating a consumer on the IRIS side.
## Alerting
Here we have a flexible alerting module to set up subscriptions and ways to deliver alerts when something goes wrong in our data flows.
### How alerting works
You should create a process in the Production based on `Alert.Process.Router` class and call it `Ens.Alert`. The process, with this name, will automatically collect all alerts from Production items for which raised flag `Alert on Error`. It is the default way described in the documentation here.

Next, you need to fill `Lookup Tables` named by notifier types. For example, table names can be like `Alert.Operation.EmailNotifier`, `Alert.Operation.SMSNotifier` and so on (you can add your own notifier implementations to the `Alert.Operation.*` package). It should be the names of Production config items. But I strongly recommend using class names for Production item names always when it is possible.

For each of these tables, `Key` means the source of the exception (name of Production business host), `Value` means contact ID (e-mail address for `EmailNotifier`, for example).