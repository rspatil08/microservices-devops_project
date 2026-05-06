# Kubernetes Manifests

These manifests deploy the Online Boutique microservices 
to AWS EKS.

## Changes from Original
- All image URLs updated to point to AWS ECR:
  `552357224711.dkr.ecr.eu-north-1.amazonaws.com/<service>:latest`
- Deployed via Jenkins CI/CD pipeline automatically

## Deploy Manually
```bash
kubectl apply -f kubernetes-manifests/ --validate=false
```

## Services Deployed
- frontend, adservice, cartservice, checkoutservice
- currencyservice, emailservice, loadgenerator
- paymentservice, productcatalogservice
- recommendationservice, shippingservice, redis-cart