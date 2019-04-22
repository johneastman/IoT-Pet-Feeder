import paho.mqtt.client as mqtt
import RPi.GPIO as GPIO
import json
import random
import time

class Feeder:
    
    def __init__(self, client_id):
        
        self.can_feed = True
        
        self.SERVO = 18
        self.TRIG = 16
        self.ECHO = 20
        
        self.CLOSE = 100
        self.OPEN = 180
        
        # GPIO Setup
        GPIO.setmode(GPIO.BCM)
        GPIO.setup(self.SERVO, GPIO.OUT)
        GPIO.setup(self.TRIG, GPIO.OUT)
        GPIO.setup(self.ECHO, GPIO.IN)

        self.pwm = GPIO.PWM(self.SERVO, 100)
        self.pwm.start(5)
        
        # Get information about the broker
        self.broker_info = self.get_server_info()
        
        # Map each topic associated with on_message to its assigned functionality
        self.on_message_topics = {"feeder/manual": self.feed_pet,
                                  "feeder/override": self.manual_override}
        
        # Initialize mqtt client
        self.mqttc = mqtt.Client(client_id, clean_session=False)
        self.mqttc.username_pw_set(self.broker_info["USERNAME"],
                                   self.broker_info["PASSWORD"])
        self.mqttc.on_message = self.on_message
        self.mqttc.connect(self.broker_info["SERVER"], int(self.broker_info["PORT"]), 60)

        # Subscribe to topics that facilitate sending data to the server
        for topic in self.on_message_topics:
            self.mqttc.subscribe(topic)
        
        self.mqttc.loop_start()
        
    def distance(self):
        """Get the distance from the ultrasonic sensor.

        Source:
        https://tutorials-raspberrypi.com/raspberry-pi-ultrasonic-sensor-hc-sr04/
        """
        # set Trigger to HIGH
        GPIO.output(self.TRIG, True)
     
        # set Trigger after 0.01ms to LOW
        time.sleep(0.00001)
        GPIO.output(self.TRIG, False)
     
        StartTime = time.time()
        StopTime = time.time()
     
        # save StartTime
        while GPIO.input(self.ECHO) == 0:
            StartTime = time.time()
     
        # save time of arrival
        while GPIO.input(self.ECHO) == 1:
            StopTime = time.time()
     
        # time difference between start and arrival
        TimeElapsed = StopTime - StartTime
        # multiply with the sonic speed (34300 cm/s)
        # and divide by 2, because there and back
        distance = (TimeElapsed * 34300) / 2
     
        return distance
    
    def on_message(self, client, userdata, message):
        topic = message.topic
        message_string = str(message.payload.decode("utf-8"))
        self.on_message_topics[topic](message_string)
        
    def manual_override(self, message):
        self.can_feed = (message == "On")
        
    def move_door(self, angle):
        duty = float(angle) / 10.0 + 2.5
        self.pwm.ChangeDutyCycle(duty)

    def feed_pet(self, message):
        self.move_door(self.OPEN)
        time.sleep(2)
        self.move_door(self.CLOSE)
        self.mqttc.publish("feeder/feeding", "")
    
    def start(self):
        start_time = time.time()
        try:
            while True:
                if time.time() - start_time >= 2:
                    distance = self.distance()
                    if distance < 30 and self.can_feed:
                        self.mqttc.publish("feeder/proximity_feeding", "")
                        self.feed_pet("")
                    start_time = time.time()
                
        except KeyboardInterrupt:
            GPIO.cleanup()
      
    def get_server_info(self):
        """Return dictionary with info in info.txt.

        info.txt contains the following information about the MQTT broker:
            USERNAME   Broker username
            PASSWORD   Broker password
            SERVER     Broker server
            PORT       Broker port
        """
        with open("info.txt", "r") as file:
            lines = [line.split(":", 1) for line in file.read().splitlines()]
        return {key:value for key, value in lines}


if __name__ == "__main__":
    feeder = Feeder("Pet Feeder")
    feeder.start()


