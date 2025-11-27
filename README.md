# TickTalk

TickTalk is a mobile timer app that offers voice activated timer creation, audio-haptic feedback on remaining time at request, and the ability to design and query complex timer routines such as repeated sets for exercise or pomodoro study. Unlike other timer apps, TickTalk allows the user to program specific intervals at which to receive feedback instead of repeatedly having to ask how much time remains, and create advanced timers that convey more information aloud such as current set (in the case of timed exercise).

# ✨Features:

* Voice Control Timer Creation: Users can create complex timers through vocal commands  
  Example: A user wants to create a Pomodoro timer to study, so they tell TickTalk to “create a timer with 4 sets of 25 minutes with 5 minute breaks in between”  
* Voice Control Timer Queries: Users can ask the timer how much time is left, and which set of the timer they are currently on  
  Example: A user is on the second stage of their Pomodoro, but is so wrapped up in study they forget whether they’ve gone through two or three stages. They can ask TickTalk “which set am I on?” and it will vocalize the information to the user.  
* Customizable Time Updates:The user can specify whether they would like TickTalk to regularly vocalize the remaining time, and by what interval  
  Example: A user does not want to have to ask repeatedly how much time is remaining on the timer, so they set the timer to vocalize or buzz at a specified interval.  


Development Platform: Android  
Hardware Requirement: Smart Mobile Device

# 🛠️Tech Stack  

This project is built using the following technologies:  
Framework: Flutter  
Language: Dart  
IDE: Android Studio  

# Architecture Overview
TickTalk uses a Layered Architecture with feature-based modules, ensuring clean separation between UI, business logic, and external services.

UI Layer: Flutter screens, widgets, navigation

Logic Layer: Timer logic, stopwatch logic, routines, voice routing

Infrastructure Layer: Google STT, Gemini 2.0 LLM, FastAPI backend

# Cloud Infrastructure
The app is cloud-connected through a 3-tier setup:

Flutter App: Captures commands, provides TTS & haptics

FastAPI Backend: Handles AI logic and routes commands

Google Cloud Services: STT + Gemini 2.0 interpretation

# CI/CD Pipeline
Every push to main triggers:

Flutter dependency installation

Release APK build (per ABI)

Automatic upload to GitHub Releases

You can download the latest APKs directly from the Releases tab.

# Roadmap
Deploy backend to Cloud Run

Add user accounts & cloud syncing

Add offline STT fallback

Expand voice capabilities

# Prerequisites

Flutter SDK installed on your machine  
Android Studio with Flutter plugins  

