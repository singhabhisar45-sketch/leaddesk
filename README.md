live url - https://resilient-monstera-e9dd9f.netlify.app/

## Tech Stack

## Frontend
- flutter (flutter web)

## Backend
- golang
- rest api

## Database
- PostgreSQL

##Cloud & Deployment
- AWS EC2
- Netlify


##REST API

  Method | Endpoint | Description |
 -------- |----------|-------------|
 POST| /api/login | authenticate admin and return jwt token |
 POST | /api/leads | create a new lead |
 GET | /api/leads | retrieve all leads (jwt protected) |
 PATCH | /api/leads/{id}/status | update lead status (jwt protected) |
 GET | /health | health check endpoint |

authentication is implemented using jwt tokens. The frontend communicates with the Go backend hosted on AWS EC2 via rest apis over http on port 8080.

##DATA FLOW

Landing Page
      │
POST /api/leads
      │
      ▼
Go backend
      │
      ▼
Postgresql


Admin login
      │
POST /api/login
      │
jwt token
      │
      ▼
GET /api/leads
PATCH /api/leads/{id}/status

Creation :
- created the whole application with the ai assitant as my partner for heavylifting and lenghty work like writing the codes , then i read the codes to find any loops and missing function in it , after all ok, i started my server and deployed the web ,
