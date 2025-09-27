Class Production.Main Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="Production.Main" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description></Description>
  <ActorPoolSize>2</ActorPoolSize>
  <Setting Target="Adapter" Name="ShutdownTimeout">30</Setting>
  <Item Name="Broker.Operation.Put2Inbox" Category="" ClassName="Broker.Operation.Put2Inbox" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Broker.Process.MessageRouter" Category="" ClassName="Broker.Process.MessageRouter" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="CollectPerformance">1</Setting>
  </Item>
  <Item Name="Inbox.Process.OnMessage" Category="" ClassName="Inbox.Process.OnMessage" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Inbox.Service.API" Category="" ClassName="Inbox.Service.API" PoolSize="0" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Sample.Process.CustomerOrderHandler" Category="" ClassName="Sample.Process.TestHandler" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="AlertOnError">1</Setting>
  </Item>
  <Item Name="Sample.Service.CustomerOrderConsumer" Category="" ClassName="Broker.Service.InboxReader" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="MessageHandler">Sample.Process.CustomerOrderHandler</Setting>
    <Setting Target="Adapter" Name="MessageType">Sample.Message.CustomerOrder.Order</Setting>
  </Item>
  <Item Name="Alert.Operation.LogFileNotifier" Category="" ClassName="Alert.Operation.LogFileNotifier" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="true" Schedule="">
    <Setting Target="Adapter" Name="FilePath">/tmp/</Setting>
  </Item>
  <Item Name="Ens.Alert" Category="" ClassName="Alert.Process.Router" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
  </Item>
  <Item Name="Sample.Process.StringArrayHandler" Category="" ClassName="Sample.Process.TestHandler" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Host" Name="AlertOnError">1</Setting>
    <Setting Target="Host" Name="ThrowError">0</Setting>
  </Item>
  <Item Name="Sample.Service.StringArrayConsumer" Category="" ClassName="Broker.Service.InboxReader" PoolSize="1" Enabled="true" Foreground="false" Comment="" LogTraceEvents="false" Schedule="">
    <Setting Target="Adapter" Name="MessageType">Sample.Message.SomeArray.Root</Setting>
    <Setting Target="Adapter" Name="MessageHandler">Sample.Process.StringArrayHandler</Setting>
  </Item>
</Production>
}

}
