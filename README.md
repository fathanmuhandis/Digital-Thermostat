# Digital Thermostat
## Introduction to the problem and the solution
---
In today's world, energy conservation is a crucial factor for sustainability. The increasing cost of energy and its impact on the environment has led to the development of various technologies that enable us to conserve energy. One such technology is the digital thermostat, which helps in regulating the temperature of a building or a room to optimize energy consumption. Digital thermostats have replaced the traditional mechanical thermostats and offer greater precision and control over temperature settings.

Traditional mechanical thermostats are known for their inaccuracies and inefficiencies. They are difficult to calibrate and can result in inconsistent temperature control, leading to energy wastage. Moreover, they cannot be programmed to adjust temperature settings according to specific schedules, which can also lead to energy wastage. The lack of control and accuracy in traditional thermostats can result in increased energy consumption and higher energy bills.

Digital thermostats offer a solution to the problems associated with traditional thermostats. They are equipped with microprocessors that enable accurate temperature sensing and control. Digital thermostats can be programmed to adjust temperature settings according to specific schedules, resulting in optimized energy consumption. They can also be remotely controlled using smartphones or other devices, allowing for greater flexibility in temperature control. Additionally, digital thermostats can display energy usage information, enabling users to track and analyze their energy consumption patterns. Overall, digital thermostats provide a more efficient and precise way to regulate the temperature of a building or a room, leading to energy conservation and cost savings.

## Hardware design and implementation details
---
The room temperature will be controlled using a potentiometer as a knob. There will also be a room temperature reading from a DHT11 sensor installed, and it will transmit data via a serial connection. The target temperature and current temperature will be displayed on a 7-Segment Display. The temperature control will also affect a mini servo SG90 that will show the temperature change command from the potentiometer.

To implement this system, the following hardware components will be required:

Microcontroller: A microcontroller will be used to manage and control the system.
Potentiometer: A potentiometer will be used as a knob to control the room temperature.
DHT11 Sensor: A DHT11 sensor will be used to measure the room temperature.
Serial Connection: A serial connection will be used to transmit the temperature data from the sensor to the microcontroller.
7-Segment Display: A 7-Segment Display will be used to display the target temperature and the current temperature.
Mini Servo SG90: A mini servo SG90 will be used to control the heating or cooling system in the room.

The implementation of this system will involve the following steps:

1. Install the potentiometer as the control knob for the temperature control.
2. Install the DHT11 sensor to measure the room temperature and transmit data via the serial connection to the microcontroller.
3. Connect the serial connection to the microcontroller and display the temperature data on the 7-Segment Display.
4. Implement the mini servo SG90 to control the heating or cooling system in the room.
5. Connect the mini servo SG90 to the microcontroller to receive commands for temperature control.
6. Test the system to ensure proper functionality and adjust the temperature control as necessary.

Overall, this hardware design and implementation will provide a reliable and effective means of controlling the temperature in a room using a potentiometer, DHT11 sensor, microcontroller, serial connection, 7-Segment Display, and mini servo SG90.

## Software implementation details
---


## Test results and performance evaluation
---
![Progress_1](assets/Progress_1.jpg)

## Conclusion and future work
---

