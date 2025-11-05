# KubeCon AI Troubleshooting Demo

This directory contains modified versions of the microservices-demo that introduce various application layer issues for demonstrating AI-powered troubleshooting capabilities with AKS CLI agents.

## Demo Scenarios

### 1. Memory Leak Scenario (`recommendationservice-memory-leak.yaml`)
**Issue**: Gradual memory consumption leading to OOM kills
**Symptoms**: 
- Pods being OOMKilled and restarted frequently
- Memory usage steadily increasing over time
- Performance degradation as memory pressure increases

**Configuration**:
- `ENABLE_MEMORY_LEAK=true`: Activates memory leak simulation
- Restrictive memory limits (200Mi) to accelerate the issue
- Cache that grows indefinitely with each request

**AI Troubleshooting Commands**:
```bash
# Analyze memory usage patterns
kubectl top pods | grep recommendation
kubectl describe pod <recommendation-pod> | grep -A 5 -B 5 OOMKilled
kubectl logs <recommendation-pod> --previous | grep -i memory

# Using AKS AI agent to analyze
az aks get-diagnostics --resource-group <rg> --name <cluster> --detector MemoryIssues
```

### 2. Database Connection Issues (`cartservice-connection-issues.yaml`)
**Issue**: Intermittent Redis connection failures with exponential backoff
**Symptoms**:
- Increased latency for cart operations
- gRPC UNAVAILABLE errors
- Connection timeout errors in logs

**Configuration**:
- `SIMULATE_CONNECTION_ISSUES=true`: Enables connection failure simulation
- `CONNECTION_FAILURE_RATE=0.4`: 40% of requests fail initially
- Exponential backoff retry mechanism

**AI Troubleshooting Commands**:
```bash
# Check connection errors
kubectl logs deployment/cartservice | grep -i "connection\|timeout\|retry"
kubectl describe svc redis-cart
kubectl get endpoints redis-cart

# Network troubleshooting
kubectl exec -it <cartservice-pod> -- nslookup redis-cart
```

### 3. CPU Spike Issues (`currencyservice-cpu-spikes.yaml`)
**Issue**: Periodic CPU-intensive operations causing throttling
**Symptoms**:
- CPU throttling events
- Increased response times during spikes
- CPU usage hitting limits

**Configuration**:
- `SIMULATE_CPU_SPIKES=true`: Enables CPU spike simulation
- `CPU_SPIKE_FREQUENCY=0.3`: 30% of requests trigger CPU spikes
- Low CPU limits (100m) to trigger throttling quickly

**AI Troubleshooting Commands**:
```bash
# Monitor CPU usage and throttling
kubectl top pods | grep currency
kubectl describe pod <currency-pod> | grep -i throttl
kubectl get events --field-selector involvedObject.name=<currency-pod>
```

### 4. gRPC Timeout Issues (`paymentservice-timeout-issues.yaml`)
**Issue**: Random delays in payment processing causing upstream timeouts
**Symptoms**:
- gRPC deadline exceeded errors
- Checkout failures
- Intermittent payment processing issues

**Configuration**:
- `SIMULATE_PAYMENT_DELAYS=true`: Enables delay simulation
- `PAYMENT_DELAY_FREQUENCY=0.4`: 40% of requests have delays
- 3-8 second processing delays

**AI Troubleshooting Commands**:
```bash
# Check for timeout errors
kubectl logs deployment/checkoutservice | grep -i "deadline\|timeout"
kubectl logs deployment/paymentservice | grep -i "delay\|timeout"

# Trace request flows
kubectl port-forward svc/frontend 8080:80
# Access application and monitor checkout process
```

### 5. Health Check Failures (`adservice-health-failures.yaml`)
**Issue**: Intermittent health check failures causing pod restarts
**Symptoms**:
- Pods in CrashLoopBackOff or constantly restarting
- Readiness/liveness probe failures
- Service endpoints flapping

**Configuration**:
- `SIMULATE_HEALTH_CHECK_FAILURES=true`: Enables health check simulation
- `HEALTH_CHECK_FAILURE_RATE=0.25`: 25% chance of failure per check
- 15-second failure duration

**AI Troubleshooting Commands**:
```bash
# Check pod restart patterns
kubectl get pods -w | grep adservice
kubectl describe pod <adservice-pod> | grep -i "probe\|health"
kubectl logs <adservice-pod> | grep -i health
```

## Circuit Breaker Pattern Demonstration

### Frontend Service with Circuit Breaker
The frontend service can be modified to implement circuit breaker patterns when calling downstream services. This helps demonstrate how services can gracefully handle failures.

**Key Features**:
- Automatic failure detection
- Fallback mechanisms
- Service degradation patterns
- Recovery monitoring

## Demo Flow

1. **Deploy Normal Application**:
   ```bash
   kubectl apply -f kubernetes-manifests/
   ```

2. **Generate Baseline Load**:
   ```bash
   kubectl apply -f kubernetes-manifests/loadgenerator.yaml
   ```

3. **Introduce Issues One by One**:
   ```bash
   # Start with memory leak
   kubectl apply -f demo-troubleshooting-manifests/recommendationservice-memory-leak.yaml
   
   # Add connection issues
   kubectl apply -f demo-troubleshooting-manifests/cartservice-connection-issues.yaml
   
   # Continue with other issues...
   ```

4. **Demonstrate AI Troubleshooting**:
   - Use AKS CLI agent commands
   - Show log analysis and correlation
   - Demonstrate automated issue detection
   - Present resolution recommendations

## Environment Variables Reference

| Service | Variable | Purpose | Default |
|---------|----------|---------|---------|
| Recommendation | `ENABLE_MEMORY_LEAK` | Enable memory leak simulation | `false` |
| Cart | `SIMULATE_CONNECTION_ISSUES` | Enable connection failure simulation | `false` |
| Cart | `CONNECTION_FAILURE_RATE` | Percentage of requests that fail | `0.3` |
| Currency | `SIMULATE_CPU_SPIKES` | Enable CPU spike simulation | `false` |
| Currency | `CPU_SPIKE_FREQUENCY` | Percentage of requests with CPU spikes | `0.1` |
| Payment | `SIMULATE_PAYMENT_DELAYS` | Enable payment delay simulation | `false` |
| Payment | `PAYMENT_DELAY_FREQUENCY` | Percentage of requests with delays | `0.3` |
| Ad | `SIMULATE_HEALTH_CHECK_FAILURES` | Enable health check failures | `false` |
| Ad | `HEALTH_CHECK_FAILURE_RATE` | Rate of health check failures | `0.2` |

## Tips for Demo

1. **Start Simple**: Begin with one issue type to establish baseline understanding
2. **Show Progression**: Demonstrate how issues compound and interact
3. **Real-time Monitoring**: Use `kubectl top`, `kubectl get events -w`, and log streaming
4. **AI Integration**: Highlight how AI agents correlate symptoms across services
5. **Resolution**: Show both manual and AI-suggested remediation steps

## Clean Up

```bash
# Remove troubleshooting manifests
kubectl delete -f demo-troubleshooting-manifests/

# Restore normal operation
kubectl apply -f kubernetes-manifests/
```