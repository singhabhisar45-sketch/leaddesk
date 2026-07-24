FROM golang:1.22-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy the backend code into the container
COPY backend/ ./

# Download Go modules
RUN go mod download

# Build the Go application
RUN go build -o server .

# Expose port 8080
EXPOSE 8080

# Run the server
CMD ["./server"]
