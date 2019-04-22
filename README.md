# IoT-Pet-Feeder
This is an Internet of Things (IoT) Pet Feeder prototype that was developed for our final project in an IoT course at Champlain College. This project was developed by Caitlin Chapdelaine and John Eastman.

## Main Features
The app consists of two primary views: the main view and the settings view. The main view is where the user primarily interacts with the app, feeding their pet manually and seeing how many times their pet has been fed. The settings view allows the user to set the number of times the pet is fed and enable or disable the ultrasonic sensor on the feeder.

| Main View | Settings View |
|:---------:|:-------------:|
| ![Main View](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/Simulator%20Screen%20Shot%20-%20iPhone%208%20-%202019-04-22%20at%2017.05.15.png) | ![Settings View](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/Simulator%20Screen%20Shot%20-%20iPhone%208%20-%202019-04-22%20at%2017.06.02.png) |

The app connects to a Raspberry Pi via an MQTT broker. With the app, the user can interact with a servo that moves a door intended to dispense pet food. An ultrasonic sensor also detects the proximity of pets, and when a pet gets close enough, food is automaticlly dispenced and the user is informed that their pet has been fed.

## Running the App
The app was develop in Xcode with Swift 5. The app uses CocoaMQTT, which was installed with CocoaPods. To run the app, open the Xcode workspace file (PetFeeder.xcworkspace).

The server was written in Python. The required dependencies for this script are [paho-mqtt](https://pypi.org/project/paho-mqtt/) and [RPi.GPIO](https://pypi.org/project/RPi.GPIO/). This script was run on a Raspberry Pi.

The broker was setup using [CloudMQTT](https://www.cloudmqtt.com/).

## Prototype Images
The following are images of the physical prototype that was created for this project.

### Front of Feeder
![Front](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/feeder_front.jpg)

### Back of Feeder 
![Back](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/feeder_back.jpg)

### Door Closed
![Closed](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/servo_door_closed.jpg)

### Door Open
![Open](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/servo_door_open.jpg)

### Ultrasonic Sensor
![Sensor](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/images/proximity_sensor.jpg)

## Discussion
If we were to keep working on this project, we would have implemented a feature that would reset the number of times the pet has been fed every day. On the settings view, the textfield labeled "Feedings Per Day" implies that this feature is implemented, but due to time constraints, we were unable to implement this feature.

This project collects data from the ultrasonic sensor but it does not store this information. It uses the data it gets to help determine if the servo should open the door to dispense food.

## License
This project is licensed under the [MIT License](https://github.com/johneastman/IoT-Pet-Feeder/blob/master/LICENSE).
