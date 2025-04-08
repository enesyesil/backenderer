# backenderer -- Backend Platform with AWS and Terraform 
![Project Status: Planning](https://img.shields.io/badge/status-planning-yellow)


Backenderer is a backend deployment platform I’m building from scratch as a personal project. It allows developers to deploy their containerized backend applications (like Spring Boot, Flask, Express, etc.) using GitHub and Docker, and automatically routes them to unique URLs on a single EC2 instance.

This platform is designed to start lightweight — using Docker and Nginx on a single AWS EC2 machine — while still following infrastructure-as-code principles with Terraform. In the future, it can scale to more complex setups like ECS, Lambda, or multi-cloud environments.

---

## Features

- Deploy any backend stack via Docker and GitHub Actions
- Dynamic route mapping per app: `https://api.backenderer.com/{user}/{app}`
- Apps run in isolated containers on a shared EC2 instance
- Reverse proxy via Nginx (routes requests to the correct container)
- GitHub Action builds, pushes, and deploys the app automatically
- Terraform-provisioned infrastructure (EC2, networking, security groups)
- Easy to maintain, extremely cost-effective in early stages

---

## How It Works

1. You write a backend app with a `Dockerfile` and a `backenderer.yml` config.
2. You push your code to GitHub.
3. A GitHub Action builds the Docker image, pushes it to a registry (ECR or Docker Hub), SSHs into the EC2 instance, and deploys it.
4. The app is automatically routed via Nginx.



---

## **Core Components**

Backenderer is composed of the following core components:

- **EC2 Instance (AWS)**  
  A single Amazon EC2 instance runs all user-deployed backend containers using Docker. It is provisioned and managed using Terraform.

- **Docker**  
  Every backend application is packaged and deployed as a Docker container. Containers are run on dynamic ports and isolated per user and app.

- **Nginx Reverse Proxy**  
  Nginx serves as a central entry point, routing incoming requests to the appropriate container using dynamic URL paths like `/user123/inventory-api`.

- **GitHub Actions (CI/CD)**  
  Users deploy their applications by pushing to their GitHub repository. A GitHub Action builds and pushes the Docker image, then connects to the EC2 host to deploy and start the container.

- **backenderer.yml**  
  Each application repository includes a `backenderer.yml` configuration file that defines the app name, owner ID, port, and other metadata used during deployment and routing.

- **Terraform (Infrastructure as Code)**  
  Terraform provisions and manages the EC2 host, networking, and security group configurations.

- **Docker Registry (ECR or Docker Hub)**  
  Built container images are pushed to a container registry. The EC2 host pulls the images before running them.


---

## **Prerequisites**

To deploy your backend application to Backenderer, you must have the following:

### Tools Installed Locally

- **Docker** — for building your backend app as a container image.
- **Git** — to manage your project and push changes to GitHub.
- **YAML support in CI** — `yq` (used in GitHub Actions for reading `backenderer.yml`).

### GitHub Repository Structure

- A valid `Dockerfile` in the root or project directory.
- A `backenderer.yml` file containing metadata for the app.
- A GitHub Actions workflow (`.github/workflows/deploy.yml`) that handles deployment.

### Required GitHub Secrets (in your app repo)

| Secret Name            | Purpose                                              |
|------------------------|------------------------------------------------------|
| `AWS_ACCESS_KEY_ID`    | For pushing Docker images to your ECR repo           |
| `AWS_SECRET_ACCESS_KEY`| For accessing AWS services securely                  |
| `ECR_REPO_URL`         | Your Docker image registry URL (ECR or Docker Hub)   |
| `EC2_HOST`             | IP or domain name of the Backenderer EC2 instance    |
| `EC2_USER`             | SSH user for the EC2 instance (typically `ec2-user`) |
| `DEPLOY_KEY`           | SSH private key to access EC2 and run deployment     |

---

## **Usage**

To deploy your backend app to Backenderer:

1. Ensure your repository includes a `Dockerfile`, `backenderer.yml`, and GitHub Actions workflow.
2. Make sure the required GitHub Secrets are configured.
3. Push your code to the main branch.
4. Backenderer will build, deploy, and route your app automatically.


---

## **High-Level Architecture Breakdown**


![Architecture Overview](./diagram.png)

---

## **High-Level Component Breakdown**

Backenderer is split into a few major components so I can manage things cleanly and scale later without rebuilding everything from scratch. Each part handles a focused job, which makes it easier to update or swap out later as the project grows.

### 1. Infrastructure (Terraform)
This is the part that sets up the whole environment. I use Terraform to provision an EC2 instance on AWS, install Docker and Nginx, open up ports, and configure security groups. It’s a one-time setup unless I want to scale it later.

- Code lives in: `backenderer-infra/`

---

### 2. Deployment Engine
This handles pulling the app’s Docker image, running it on the EC2 instance, and assigning it a port. It’s triggered from GitHub Actions and can also be run manually if needed (later I might make this a CLI or lightweight service).

---

### 3. Routing Layer
When a new app is deployed, it gets its own Nginx route. This layer generates a config that maps a path like `/user123/todo-api` to the right container and port. After updating, it reloads Nginx to apply the new routes.

---

### 4. CI/CD (GitHub Actions)
Each backend repo that wants to deploy to Backenderer uses a GitHub Action. It reads the config file (`backenderer.yml`), builds the image, pushes it to a Docker registry, and then deploys it to the EC2 host via SSH.

---

### 5. App Metadata
This is the info that tells Backenderer what to do. Each app has a `backenderer.yml` file that includes stuff like:
```yaml
app_name: todo-api
owner_id: user123
container_port: 5000 
```
---

### 6. Docker Image + Registry
Apps get built into Docker images and pushed to a container registry. I’m using Amazon ECR for now, but Docker Hub would work too. When it’s time to deploy, the EC2 host pulls the image using the tag from the GitHub Action.

---

### 7. Local Container Tracking
This part just keeps track of what’s running on the EC2 host. I’m using a simple `app-registry.json` file that logs:

- Which apps are deployed
- What port each container is running on
- Who owns it

---

### **8. (Optional) Dashboard/API Layer**
- **Purpose**: Future enhancement to allow visual management of deployed apps.
- **Features**: View running containers, routes, logs, and usage.
- **Status**: Planned for future phases.
- But I guess it would take time for this to develop. 



