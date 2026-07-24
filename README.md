live url - https://resilient-monstera-e9dd9f.netlify.app/

## Tech Stack

## Frontend
- Flutter (Flutter Web)

## Backend
- Golang
- REST API

## Database
- PostgreSQL

##Cloud & Deployment
- AWS EC2
- Netlify


##REST API

  Method | Endpoint | Description |
 -------- |----------|-------------|
 POST| /api/login | Authenticate admin and return JWT token |
 POST | /api/leads | Create a new lead |
 GET | /api/leads | Retrieve all leads (JWT protected) |
 PATCH | /api/leads/{id}/status | Update lead status (JWT protected) |
 GET | /health | Health check endpoint |

Authentication is implemented using jwt tokens. The frontend communicates with the Go backend hosted on AWS EC2 via rest apis over http on port 8080.

##DATA FLOW

Landing Page
      │
POST /api/leads
      │
      ▼
Go Backend
      │
      ▼
PostgreSQL


Admin Login
      │
POST /api/login
      │
JWT Token
      │
      ▼
GET /api/leads
PATCH /api/leads/{id}/status

Creation :
- created the whole application with the ai assitant as my partner for heavylifting and lenghty work like writing the codes , then i read the codes to find any loops and missing function in it , after all ok, i started my server and deployed the web , 
