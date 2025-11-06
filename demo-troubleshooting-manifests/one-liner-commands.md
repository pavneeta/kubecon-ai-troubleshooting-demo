# 🎯 One-Liner Demo Commands
# Copy and paste these commands for instant demo issues

# Memory Pressure (causes OOM kills)
kubectl patch deployment recommendationservice -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","resources":{"limits":{"memory":"100Mi"}}}]}}}}'

# CPU Throttling  
kubectl patch deployment recommendationservice -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","resources":{"limits":{"cpu":"50m"}}}]}}}}'

# Pod Restart Loop
kubectl patch deployment recommendationservice -p '{"spec":{"template":{"spec":{"containers":[{"name":"server","livenessProbe":{"grpc":{"port":8080},"periodSeconds":2,"failureThreshold":1}}]}}}}'

# Service Unavailable
kubectl scale deployment recommendationservice --replicas=0

# Network Issues (using labels)
kubectl label pods -l app=recommendationservice chaos=network-delay

# Reset Everything
kubectl apply -f kubernetes-manifests/recommendationservice.yaml

# 📊 Monitoring Commands
kubectl top pods | grep recommendation
kubectl get pods -w | grep recommendation  
kubectl describe pod $(kubectl get pods -l app=recommendationservice -o jsonpath='{.items[0].metadata.name}')
kubectl logs -f deployment/recommendationservice