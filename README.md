# Personal Trainer and Client Management Application

## 1. Identify Main User Groups

### A. Personal Trainers (PT)
- Manage lists of clients.
- Create/update training programs.
- Track and monitor client progress.
- Communicate with clients (chat, notifications).
- Manage scheduling (e.g., session calendars).

### B. Clients
- View their training schedules.
- Log workout results.
- Receive instructions/messages from PTs.
- Possibly make payments or manage billing (if needed).
- Track progress (weight, measurements, performance, etc.).

---

## 2. Key Functionalities

### A. Personal Trainer (PT) Side

1. **Client Management**
   - Add or remove clients.
   - View individual client details (contact info, goals, progress).

2. **Workout/Training Program Management**
   - Create training programs (templates) or custom routines.
   - Assign training programs to clients, with schedules (e.g., Monday: upper body, Tuesday: cardio, etc.).
   - Update training sessions in real-time or schedule updates.

3. **Progress & Metrics Tracking**
   - Track measurements (weight, body fat percentage, measurements, etc.) over time.
   - Track performance metrics (rep counts, 1RM, times, etc.).
   - Graphs or charts to visualize client progress.

4. **Communication**
   - Chat or message functionality to discuss changes, ask questions, or provide feedback.
   - Push notifications for urgent updates or session reminders.

5. **Scheduling & Calendar**
   - Schedule sessions with clients.
   - Provide reminders or any scheduling updates.

6. **Analytics & Reporting** (optional but helpful)
   - Summaries of client improvements.
   - Filtering clients by last check-in date, progress trends, etc.

### B. Client Side

1. **Workout Dashboard**
   - Daily or weekly training plans.
   - Detailed instructions and media (images/videos).

2. **Logging & Progress**
   - Log exercises (reps, weights, time, etc.).
   - Keep track of personal records.
   - View personal progress graphs.

3. **Nutrition Plan** (if applicable)
   - Meal plans, macros, recommended calorie intake, etc.
   - Ability to log meals or see diet recommendations.

4. **Communication**
   - Send messages to PT.
   - Receive notifications (new workout assigned, check-in reminders, etc.).

5. **Profile & Billing** (optional, if needed)
   - View or update personal details (height, weight, etc.).
   - Payment history or subscription info (if the platform manages that).

---

## 3. Use-Case Diagram (Textual Representation)

```
 +--------------+               +--------------+
 | Personal     |               | Client       |
 | Trainer (PT) |               | (User)       |
 +--------------+               +--------------+
         |                             |
         | (1) Manage Clients          |
         |----------------------------->
         |                             |
         | (2) Create/Assign Programs  |
         |----------------------------->
         |                             |
         | (3) Track/Update Progress   |
         |----------------------------->
         |                             |
         | (4) Chat / Notifications    |
         |----------------------------->
         |                             |
         |                             |
         | <----------------------------- (1') View Training Program
         | <----------------------------- (2') Log Workout
         | <----------------------------- (3') View/Track Progress
         | <----------------------------- (4') Chat / Receive Notifications
         |                             |
         +--------------+               +--------------+
                  \                       /
                   \        (App)       /
                    \-------------------/
```

---

## 4. Basic Wireframes

### A. PT Dashboard (Desktop/Tablet View)

```
+---------------------------------------------------------+
|  Header: Logo / PT Name / Profile / Log out            |
+------------------------+--------------------------------+
|     Side Menu          |        Main Content            |
|  - Dashboard           |  [Clients Overview]            |
|  - Clients             |  ----------------------        |
|  - Programs            |  List of Clients (cards/table) |
|  - Calendar            |   - Name                       |
|  - Chat/Messages       |   - Last Activity              |
|  - Settings            |   - Progress Summary           |
|                        |   [Add New Client] button      |
|                        |                                |
|                        |  [Programs Overview]           |
|                        |  ----------------------        |
|                        |  + Create New Program          |
|                        |  + List of existing programs   |
+---------------------------------------------------------+
```

### B. Client Dashboard (Mobile View)

```
+----------------------------------------------+
| Header: App logo + Menu (hamburger icon)    |
+----------------------------------------------+
| [Today's Workout]                            |
|   - Exercise 1 (Sets, Reps, etc.)           |
|   - Exercise 2                              |
|   - [Log your workout] button               |
+----------------------------------------------+
| [Progress Summary]                           |
|   - Graph or quick stats                    |
+----------------------------------------------+
| [Messages / Notifications]                  |
|   - Preview of latest message from PT       |
+----------------------------------------------+
| [Menu Drawer - Collapsed / Slide In]        |
|   - My Profile                              |
|   - My Workouts                             |
|   - Progress Details                        |
|   - Chat                                    |
+----------------------------------------------+
```

---

## 5. High-Level Data Model

```
 +-------------+               +--------------+             +-----------------+
 |   Trainer   |1           *  |   Client     |1         *  |   WorkoutPlan   |
 | (PT)        |-------------->| (User)       |------------>| (Program Info)  |
 +-------------+               +--------------+             +-----------------+
     ^                                  ^                         ^
     |                                  |                         |
     | 1-to-Many                        | 1-to-Many               | 1-to-Many
     |                                  |                         |
     |             +--------------------|--------------------------+
     |             |
     v             v
 +-------------+   +-----------------+
 |  Exercise   | * |   WorkoutLog    |
 +-------------+   +-----------------+
     | 1-to-Many        
     v               
 +------------------+
 |   ExerciseDetail |
 +------------------+
```

### Entities & Fields

1. **Trainer**
   - `trainer_id` (PK)
   - `name`
   - `email` (unique)
   - `password` (hashed)

2. **Client**
   - `client_id` (PK)
   - `name`
   - `email`
   - `password` (hashed)
   - `trainer_id` (FK to Trainer)

3. **WorkoutPlan**
   - `plan_id` (PK)
   - `trainer_id` (FK to Trainer)
   - `title`
   - `description`
   - `assigned_to_client_id` (optional)

4. **Exercise**
   - `exercise_id` (PK)
   - `name`
   - `description`

5. **ExerciseDetail**
   - `detail_id` (PK)
   - `plan_id` (FK to WorkoutPlan)
   - `exercise_id` (FK to Exercise)
   - `sets`
   - `reps`
   - `rest_time`

6. **WorkoutLog**
   - `log_id` (PK)
   - `client_id` (FK to Client)
   - `exercise_id` (FK to Exercise)
   - `date_logged`
   - `sets_completed`
   - `reps_completed`
   - `weight_used`

---

## 6. High-Level Architecture Diagram

```
                [ Mobile App ] -------------------
                [ Web App    ] ---->  [API Layer] 
                                          |
                                          v
                         +-------------------------+
                         |   Application Server   |
                         |  (Business Logic,      |
                         |   Auth, etc.)          |
                         +-----------+------------+
                                     |
                                     v
                              [ Database Layer ]
                          (SQL / NoSQL / Cloud DB)
```

- **Front-end**
  - Responsive web (React, Vue, Angular, etc.).
  - Mobile (React Native, Flutter, etc.).

- **Back-end / API**
  - Node.js, Django, FastAPI, etc.

- **Database**
  - Relational (PostgreSQL, MySQL) or NoSQL (MongoDB).

---

## 7. Next Steps

1. **Prioritize Must-Have Features**
   - Client management, workout creation, workout logging, basic progress tracking, and simple messaging.

2. **Refine UX & UI**
   - Build lo-fi or hi-fi prototypes to test usability.

3. **Set Up Development Environments**
   - Choose frameworks.
   - Configure CI/CD pipelines.

4. **Plan for Data Security & Scalability**
   - Use secure authentication.

5. **Incremental Release Strategy**
   - Release an alpha/beta for a small group of users.

---

# How to run on emulated devices

## Android Tablet (Chrome):

### Connect to device
   adb connect 192.168.1.135
   connected to 192.168.1.135:5555

### Run in the device
   flutter run -d 192.168.1.135:5555

---

Last version before codex changes