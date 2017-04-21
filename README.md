# data-microservices
Presentation and Demonstration of Spring Cloud Stream and Task

## 0 - Prerequisites

### Install and run [Rabbit MQ](https://github.com/cppwfs/DNDataflow/blob/master/labs/InstallRabbitnMQ.pdf)

### Install and start Maria DB SQL Server

#### OS/X
```
$ brew install mariadb
$ mysql.server start  (manual start.  To stop mysql.server stop)
$ mysql_secure_installation (set the root password)
```
#### Windows:
https://downloads.mariadb.org/mariadb/5.2.6/

* The page includes an instructions link for each download

#### Create a database:
$mysql -u root -p
MariaDB [(none)]> create database spring_cloud_dataflow;
MariaDB [(none)]> exit;


## Exercise 1 - A Simple Spring Cloud Stream Demo

Time source streams to Log sink

#### Download Spring Cloud Stream OOTB apps:

On OS/X or Unix compatible shell, run the following commands:

```
$ wget https://repo.spring.io/libs-snapshot/org/springframework/cloud/stream/app/time-source-rabbit/1.2.1.BUILD-SNAPSHOT/time-source-rabbit-1.2.1.BUILD-SNAPSHOT.jar

$ wget https://repo.spring.io/libs-snapshot/org/springframework/cloud/stream/app/log-sink-rabbit/1.2.1.BUILD-SNAPSHOT/log-sink-rabbit-1.2.1.BUILD-SNAPSHOT.jar

```
or paste the URL in your browser
or use `download-app.sh log-sink-rabbit 1.2.1.BUILD-SNAPSHOT` provided in this repo.

#### Run each app in a separate terminal:

```
$ java -jar log-sink-rabbit-1.2.1.BUILD-SNAPSHOT.jar --spring.cloud.stream.bindings.input.destination=ticktock

$ java -jar time-source-rabbit-1.2.1.BUILD-SNAPSHOT.jar --spring.cloud.stream.bindings.output.destination=ticktock --server.port=8081
```

Note the current time output every second in the log-sink console

## Exercise 2 - Transform Data Using a Processor

#### Download http source and transform processor

```
$ wget https://repo.spring.io/libs-snapshot/org/springframework/cloud/stream/app/http-source-rabbit/1.2.1.BUILD-SNAPSHOT/http-source-rabbit-1.2.1.BUILD-SNAPSHOT.jar

$wget https://repo.spring.io/libs-snapshot/org/springframework/cloud/stream/app/transform-processor-rabbit/1.2.1.BUILD-SNAPSHOT/transform-processor-rabbit-1.2.1.BUILD-SNAPSHOT.jar
```

#### Run each app in separate terminal

````
$java -jar log-sink-rabbit-1.2.1.BUILD-SNAPSHOT.jar --spring.cloud.stream.bindings.input.destination=log

$java -jar transform-processor-rabbit-1.2.1.BUILD-SNAPSHOT.jar --spring.cloud.stream.bindings.input.destination=transformer --spring.cloud.stream.bindings.output.destination=log --server.port=8081 --transformer.expression="payload.toUpperCase()"

$java -jar http-source-rabbit-1.2.1.BUILD-SNAPSHOT.jar --spring.cloud.stream.bindings.output.destination=transformer --server.port=8082
````
#### Post a message to the http source

````
curl -H"Content-Type:text/plain" -X POST http://localhost:8082 -d 'Hello World'
````

## Exercise 3 - Download and Start Dataflow Server and Shell

#### Download

```
$ wget http://repo.spring.io/milestone/org/springframework/cloud/spring-cloud-dataflow-server-local/1.2.0.RC1/spring-cloud-dataflow-server-local-1.2.0.RC1.jar
$ wget http://repo.spring.io/milestone/org/springframework/cloud/spring-cloud-dataflow-shell/1.2.0.RC1/spring-cloud-dataflow-shell-1.2.0.RC1.jar
```
#### Start Dataflow Server

````
$ java -jar spring-cloud-dataflow-server-local-1.2.0.RC1.jar
````
#### Start Dataflow Shell

````
$ java -jar spring-cloud-dataflow-shell-1.2.0.RC1.jar
````

#### Use the Shell to Register OOTB Apps
```
dataflow:>app import http://bit.ly/Bacon-RELEASE-stream-applications-rabbit-maven
```

## Exercise 4 - Create a Stream: time | file

* Point your web browser to http://localhost:9393/dashboard
* Select the `Streams` tab
* Select the `time` source App from the Apps listed at the left of the page and drag it to the main panel.
* Select the `log` sink App and drag it to the main panel.
* Connect the source and sink by clicking on the `time` connection point and dragging to the `log` connection point.
* Note the stream's DSL definition in the text box.
* Click on the `Create Stream` button (the one with the blue-green border)
* Enter `ticktock` as the screen name and select `Deploy streams`
* Click on the `Definitions` tab and wait for the status to be `deployed`
* Go to the Dataflow Server console and copy the directory path of the log file for `ticktock.log instance 0`. The log will be in *[directory]/stdout_0.log*
* Tail the log file using `tail -f` or view in a text editor to see the time messages.
* Go to the shell and issue the following commands:
```
dataflow:>stream list
dataflow:>stream undeploy ticktock
dataflow:>stream list (to see it has been undeployed)
```

## Exercise 5 - Fun with Named Channels

#### Using the shell, create and deploy 3 streams:

Set a simple directory in the file sink, like `decisions` under your home directory


```
dataflow:>stream create decision --definition "http --port=9000 | router --expression=#jsonPath(payload,'$.foo')=='foo'?'foo':'other'" --deploy
dataflow:>stream create foo-stream --definition ":foo > file --directory=[some-directory] --name=foo.txt" --deploy
dataflow:>stream create other-stream --definition ":bar > file --directory=[some-directory] --name=other.txt" --deploy
```

#### Post some messages to the http source:

```
$curl -X POST -H "Content-Type:application/json" http://localhost:9000 -d '{"foo":"foo"}'
$curl -X POST -H "Content-Type:application/json" http://localhost:9000 -d '{"foo":"bar"}'
$curl -X POST -H "Content-Type:application/json" http://localhost:9000 -d '{"foo":"other"}'
$curl -X POST -H "Content-Type:application/json" http://localhost:9000 -d '{"foo":"foo"}'
$curl -X POST -H "Content-Type:application/json" http://localhost:9000 -d '{"foo":"something else"}'
```
#### Examine the contents of `foo.txt` and `other.txt`

## Exercise 6 - Write A Simple Task App

#### Go to SpringInitializr at http://start.spring.io or if using STS or Intellij, create a new Spring Initializr Project

* Name the artifact and the project name `hello-world-task`
* Select dependencies `Cloud Task`,`JDBC`,`HSQLDB`
* Unzip and import the project to your IDE


#### Edit  `HelloWorldTaskApplication.java` to look like this:

```java
@SpringBootApplication
@EnableTask
public class HelloWorldTaskApplication implements CommandLineRunner{

	public static void main(String[] args) {
		SpringApplication.run(HelloWorldTaskApplication.class, args);
	}

	@Override public void run(String... args) throws Exception {
		System.out.println("Hello, World!");
	}
}
```
#### Add `logging.level.org.springframework.cloud.task=DEBUG` to `src/main/resources/application.properties`

#### Run the application

#### Configure for MariaDB

* Make sure MariaDB is installed and running

* Add the following dependency:

```xml
<dependency>
	<groupId>org.mariadb.jdbc</groupId>
	<artifactId>mariadb-java-client</artifactId>
</dependency>
```

* and change the scope of the HSQLDB dependency to `test`:

```xml
<dependency>
	<groupId>org.hsqldb</groupId>
	<artifactId>hsqldb</artifactId>
	<scope>test</scope>
</dependency>
```
* Add the following properties to `application.properties`:

```
spring.application.name=helloWorld
spring.datasource.url=jdbc:mariadb://localhost/spring_cloud_dataflow
spring.datasource.username=root
spring.datasource.password=[your password]
spring.datasource.driverclassName=org.mariadb.jdbc.Driver
```
#### Query the TASK_EXECUTION 'table'

```
$mysql -u root -p
MariaDB [(none)]> use spring_cloud_dataflow;
Database changed
MariaDB [spring_cloud_dataflow]> select * from TASK_EXECUTION;
```

Note the `TASK_NAME` column corresponds to `spring.application.name` and `EXIT_CODE` is `0`

#### Modify the application to throw and exception and rerun it:
```java
@SpringBootApplication
@EnableTask
public class HelloWorldTaskApplication implements CommandLineRunner{

	public static void main(String[] args) {
		SpringApplication.run(HelloWorldTaskApplication.class, args);
	}

	@Override public void run(String... args) throws Exception {
		throw new RuntimeException("Uh oh!");
	}
}
```

* Query TASK_EXECUTION again

## Exercise 7 - Launch A Task From A Stream

#### Pull Starting Code From Github

````
$git clone https://github.com/dturanski/spring-cloud-stream-apps.git
$cd spring-cloud-stream-apps
$git checkout start
````
#### Import `file-tlr-transformer` into your IDE

#### Fix the test

* Run as `FileTlrTransformerApplicationTests` Junit Test

Note in the stack trace `Field error in object 'target' on field 'taskName': rejected value [null];`
This is because `FileTlrProperties.java` includes

```java
@NotNull
	public String getTaskName() {
		return taskName;
	}
```
And no taskName property has been provided.

In `FileTlrTransformerApplicationTests` add the property to `@SpringBootTest`

```java
@SpringBootTest("taskName=foo")
```
In general this annotation accepts an array of String to configure properties for testing:
```java
@SpringBootTest({"taskName=foo","myProp=someValue"})
```
Now the test should pass.

#### Implement the transformer:

Create a class called `org.spring.io.FileTaskLaunchRequestTransformer`

```java

public class FileTaskLaunchRequestTransformer {

}
```

Add a field of type `FileTlrProperties`

```java
public class FileTaskLaunchRequestTransformer {

    private FileTlrProperties properties;
}
```


Add a method that takes a String argument and returns a `SimpleTaskLaunchRequest`:
This gets the taskName from the properties object and uses it to create a key

`app.[task-name].fileName` which is the prefix that Dataflow uses to set the `fileName` property
on the correct app. The value of the file name is the value of the method parameter.

```java
public class FileTaskLaunchRequestTransformer {

  private FileTlrProperties properties;

	public SimpleTaskLaunchRequest supplyFileName(String payload) {

		return new SimpleTaskLaunchRequest(properties.getTaskName(), properties.getArgs(),
				 Collections.singletonMap(
						 String.join(".","app",properties.getTaskName(),"fileName"),
						 payload));
	}
}
```

#### Add the Spring annotations:

* `@EnableBinding` - tells Spring Cloud Stream to bind an `input` and `output` channel
to the configured middleware (Rabbit MQ in this case).
* EnableConfigurationProperties - tells Spring Boot to bind environment properties to
a `FileTlrProperties` object.
* The properites object is @Autowired to tell Spring to inject the bound properites instance into this
class.
* `@Transformer` binds the method to the declared MessageChannels (input and output). The argument value
will be the payload of the incoming message and the return value will be sent to the output channel.


```java
@EnableBinding(Processor.class)
@EnableConfigurationProperties(FileTlrProperties.class)
public class FileTaskLaunchRequestTransformer {

	@Autowired
	private FileTlrProperties properties;

	@Transformer(inputChannel = Processor.INPUT, outputChannel = Processor.OUTPUT)
	public SimpleTaskLaunchRequest supplyFileName(String payload) {

		return new SimpleTaskLaunchRequest(properties.getTaskName(), properties.getArgs(),
				 Collections.singletonMap(
						 String.join(".","app",properties.getTaskName(),"fileName"),
						 payload));
	}
}
```

## Exercise 8 - Use these components to create a Data Flow that will launch the `file-task` task, whenever a file
appears in a directory.

#### For convenience we will register the prebuilt binaries in Data Flow:


````
dataflow:>app register file-tlr-transformer --type processor -uri  https://github.com/dturanski/spring-cloud-stream-binaries/blob/master/binaries/file-tlr-transformer-1.0.0.BUILD-SNAPSHOT.jar?raw=true

dataflow:>app register simple-task-launcher --type sink --uri https://github.com/dturanski/spring-cloud-stream-binaries/blob/master/binaries/simple-task-launcher-sink-1.0.0.BUILD-SNAPSHOT.jar?raw=true

dataflow:>
dataflow:>app register file-task --type task --uri  https://github.com/dturanski/spring-cloud-task-binaries/blob/master/binaries/file-task-0.0.1-SNAPSHOT.jar?raw=true
````

#### Create the task to be launched
```
dataflow:>task create file-task --definition "file-task"
```

#### Create a Stream to poll a director for files and launch the task
```
dataflow:>stream create file-watch --definition "file --directory=[some-directory]/trade-files --mode=ref | file-tlr-transformer --taskName=file-task > :tasks"
```

#### Create a Stream to process any task launch requests
```
dataflow:>stream create task-launch --definition ":tasks > simple-task-launcher"
```

#### Deploy the two streams

#### Create a trades text file and add the following contents:

```
IBM SELL 100
VMW BUY 50
AAPL BUY 150
AMZN SELL 200
GOOGL BUY 10
```

#### Drop the file into the trade-files directory

You should see the Dataflow Server console log launch the task and will output the path of its log file directory
open stdout_0.log in that directory and you should see the contents of the file listed (each line processed by the
task).
