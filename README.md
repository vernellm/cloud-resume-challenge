# Cloud Resume Challenge

This is my iteration of the Cloud Resume Challenge. The challenge consists of using AWS
to serverless-ly deploy a static website consisting of HTML/CSS/Javascript using Amazon S3. It's fronted by CloudFront to give HTTPS security when visiting the website. It is backed by DynamoDB to store a "Visitor Counter" that is updated using a Lambda function. That function is triggered from a call to a custom API using API Gateway. The deployment is completely automated using Terraform and changes/updates are handled using GitHub Actions. 

## Prereuisites

- Node.js
- Cypress.js
- Terraform CLI
- Python
- AWS Configuration
- GitHub Actions

## How it Works

### Frontend

- Vanilla JavaScript
Inside of ```frontend``` you will see the HTML/CSS code for my static site

### Backend

- Cypress.js / Node.js

    Inside of ```backend``` you will see my spec for end-to-end testing my website. If the test passes, it indicates that my lambda function and AWS API Gateway is configured correctly.

- Terraform 
    The main.tf file is the code of my IaC infrastructure for deploying all of my AWS resources.

- Python
    The lambda_function.py file is my Lambda function code that communicates with my DynamoDB resource. Permissions are still needed to be configured in your AWS account in order for the code to work properly.

- GitHub Actions
    The GitHub Actions .yml files that update the frontend with changes to my website and updates to the backend with architectural and/or configuration changes are in their respective folders.  

- AWS Config
    In order to successfully deploy any of the resources in this repository, you must have an AWS account and it must be configured in your environment. Make sure to use your own credentials so that the architecture is deployed in your AWS account. 


## Contributing 

Feel free to open up an issue or reach out to me via email:
- vtmangum@gmail.com
