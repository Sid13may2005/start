/*
 * Bluetooth RC Car with Ultrasonic Safety Brake
 * Chassis: 4WD (as seen in 1000075587.jpg)
 * Power: 12V Supply
 * Driver: L298N
 */

// Bluetooth Command Variable
char t;

// Pin Definitions - Motor Driver
const int LEFT_FWD = 13;
const int LEFT_REV = 12;
const int RIGHT_FWD = 11;
const int RIGHT_REV = 10;

// Peripheral Pins
const int MINING_LED = 9;
const int SENSOR_VCC = 2; // Powering the sensor from a digital pin

// Ultrasonic Sensor Pins
const int TRIG = 5;
const int ECHO = 4;

// Logic Variables
int distance;
const int BRAKE_THRESHOLD = 1; // Emergency stop distance in cm

void setup() {
  // Initialize Motor Pins
  pinMode(LEFT_FWD, OUTPUT);
  pinMode(LEFT_REV, OUTPUT);
  pinMode(RIGHT_FWD, OUTPUT);
  pinMode(RIGHT_REV, OUTPUT);
  
  // Initialize LED
  pinMode(MINING_LED, OUTPUT);
  
  // Power up the Ultrasonic Sensor via Pin 2
  pinMode(SENSOR_VCC, OUTPUT);
  digitalWrite(SENSOR_VCC, HIGH); 
  
  // Initialize Sensor Logic
  pinMode(TRIG, OUTPUT);
  pinMode(ECHO, INPUT);

  // Serial for Bluetooth (Disconnect RX/TX when uploading!)
  Serial.begin(9600);
  delay(500); // Wait for sensor stabilization
}

void loop() {
  // 1. SENSE: Check distance
  distance = getDistance();

  // 2. THINK: Read Bluetooth command
  if (Serial.available()) {
    t = Serial.read();
    Serial.println(t); // Helpful for debugging in the Serial Monitor
  }

  // 3. ACT: Safety Override Logic
  // If moving Forward/Left/Right and an obstacle is too close:
  if (distance > 0 && distance < BRAKE_THRESHOLD && (t == 'F' || t == 'L' || t == 'R')) {
    applyBrakes();                  // Immediate motor lock
    digitalWrite(MINING_LED, HIGH); // Visual warning
    t = 'S';                        // Force state to Stop
  } 
  else {
    // Standard LED Control
    if (t == 'W') digitalWrite(MINING_LED, HIGH);
    else if (t == 'w') digitalWrite(MINING_LED, LOW);
    
    // Process Movement
    executeMovement(t);
  }
  
  delay(5); // Loop timing
}

// --- Helper Functions ---

int getDistance() {
  digitalWrite(TRIG, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG, LOW);
  
  // 30ms timeout prevents code freeze if sensor fails
  long duration = pulseIn(ECHO, HIGH, 10000); 
  int d = duration * 0.034 / 2;
  
  return (d == 0) ? 999 : d; // Return large distance if no echo
}

void applyBrakes() {
  // Setting both inputs HIGH on L298N creates an electronic lock
  digitalWrite(LEFT_FWD, HIGH);
  digitalWrite(LEFT_REV, HIGH);
  digitalWrite(RIGHT_FWD, HIGH);
  digitalWrite(RIGHT_REV, HIGH);
}

void allLow() {
  digitalWrite(LEFT_FWD, LOW);
  digitalWrite(LEFT_REV, LOW);
  digitalWrite(RIGHT_FWD, LOW);
  digitalWrite(RIGHT_REV, LOW);
}

void executeMovement(char cmd) {
  switch (cmd) {
    case 'B':
      allLow();
      digitalWrite(LEFT_FWD, HIGH);
      digitalWrite(RIGHT_FWD, HIGH);
      break;
      
    case 'F':
      allLow();
      digitalWrite(LEFT_REV, HIGH);
      digitalWrite(RIGHT_REV, HIGH);
      break;
      
    case 'R': // Pivot Turn Left
      allLow();
      digitalWrite(LEFT_REV, HIGH);
      digitalWrite(RIGHT_FWD, HIGH);
      break;
      
    case 'L': // Pivot Turn Right
      allLow();
      digitalWrite(LEFT_FWD, HIGH);
      digitalWrite(RIGHT_REV, HIGH);
      break;
      
    case 'S':
      allLow(); // Coasting Stop
      break;
  }
}