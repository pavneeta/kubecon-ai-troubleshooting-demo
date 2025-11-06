# 🎯 KubeCon AI Troubleshooting Demo

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Kubernetes](https://img.shields.io/badge/kubernetes-v1.20+-blue.svg)](https://kubernetes.io/)
[![AKS](https://img.shields.io/badge/Azure%20Kubernetes%20Service-Compatible-blue.svg)](https://azure.microsoft.com/en-us/services/kubernetes-service/)

## Overview

This repository contains a **modified version** of the [Google Cloud Platform microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo) specifically designed to showcase **AI-powered troubleshooting capabilities** in Azure Kubernetes Service (AKS). 

Perfect for **KubeCon demonstrations**, this setup introduces realistic application layer issues that can be diagnosed and resolved using AI agents and CLI tools.

## 🚀 What's New

### Demo-Specific Issues Added

1. **Memory Leak Simulation** (Recommendation Service)
   - Controllable memory consumption
   - Demonstrates OOM scenarios and pod restarts
   - Shows memory usage pattern analysis

2. **Database Connection Issues** (Cart Service)
   - Intermittent Redis connection failures
   - Connection timeout and retry scenarios
   - Network troubleshooting demonstrations

3. **CPU Spike Issues** (Currency Service)
   - Periodic CPU-intensive operations
   - CPU throttling and resource constraint analysis
   - Performance degradation scenarios

4. **gRPC Timeout Issues** (Payment Service)
   - Random processing delays
   - Upstream timeout failures
   - Distributed system failure analysis

5. **Health Check Failures** (Ad Service)
   - Intermittent health check failures
   - Pod flapping and service instability
   - Kubernetes health management issues

## 📁 Repository Structure

```
├── demo-troubleshooting-manifests/     # Problematic Kubernetes manifests
│   ├── README.md                       # Detailed documentation
│   ├── demo-script.sh                  # Interactive demo script
│   ├── *-memory-leak.yaml             # Memory leak scenarios
│   ├── *-connection-issues.yaml       # Connection problem scenarios
│   ├── *-cpu-spikes.yaml             # CPU spike scenarios
│   ├── *-timeout-issues.yaml         # Timeout problem scenarios
│   └── *-health-failures.yaml        # Health check failure scenarios
├── src/                               # Modified microservices code
│   ├── recommendationservice/         # With memory leak simulation
│   ├── cartservice/                   # With connection retry logic
│   ├── currencyservice/              # With CPU spike simulation
│   ├── paymentservice/               # With timeout simulation
│   └── adservice/                    # With health check failures
└── kubernetes-manifests/             # Original working manifests
```

## 🎪 Demo Flow

### Prerequisites
- Azure Kubernetes Service (AKS) cluster
- `kubectl` configured to access your cluster
- AKS AI CLI agent tools installed
- Load generator for realistic traffic

### Quick Start

1. **Deploy the baseline application**:
   ```bash
   kubectl apply -f kubernetes-manifests/
   ```

2. **Generate baseline load**:
   ```bash
   kubectl apply -f kubernetes-manifests/loadgenerator.yaml
   ```

3. **Run the interactive demo**:
   ```bash
   chmod +x demo-troubleshooting-manifests/demo-script.sh
   ./demo-troubleshooting-manifests/demo-script.sh
   ```

### Manual Demo Steps

1. **Introduce Memory Leak**:
   ```bash
   kubectl apply -f demo-troubleshooting-manifests/recommendationservice-memory-leak.yaml
   # Watch for OOM kills and memory pressure
   kubectl top pods -w | grep recommendation
   ```

2. **Add Connection Issues**:
   ```bash
   kubectl apply -f demo-troubleshooting-manifests/cartservice-connection-issues.yaml
   # Monitor connection failures
   kubectl logs deployment/cartservice -f | grep -i "connection\|retry\|timeout"
   ```

3. **Trigger CPU Spikes**:
   ```bash
   kubectl apply -f demo-troubleshooting-manifests/currencyservice-cpu-spikes.yaml
   # Observe CPU throttling
   kubectl top pods | grep currency
   ```

4. **Introduce gRPC Timeouts**:
   ```bash
   kubectl apply -f demo-troubleshooting-manifests/paymentservice-timeout-issues.yaml
   # Watch for deadline exceeded errors
   kubectl logs deployment/checkoutservice | grep -i deadline
   ```

5. **Create Health Check Failures**:
   ```bash
   kubectl apply -f demo-troubleshooting-manifests/adservice-health-failures.yaml
   # Monitor pod restart patterns
   kubectl get pods -w | grep adservice
   ```

## 🤖 AI Troubleshooting Commands

Use these commands to demonstrate AI-powered troubleshooting:

### Memory Issues Analysis
```bash
# Collect diagnostics
az aks kollect --resource-group <rg> --name <cluster>

# AI-powered analysis
kubectl top pods --sort-by=memory
kubectl describe pod <pod-name> | grep -A 10 -B 10 OOMKilled

# Query AI agent for memory optimization
az aks ai-troubleshoot --issue "memory-pressure" --component "recommendationservice"
```

### Connection Issues Analysis
```bash
# Network troubleshooting
kubectl logs deployment/cartservice | grep -E "connection|timeout|retry"
kubectl get endpoints redis-cart
kubectl describe svc redis-cart

# AI network analysis
az aks ai-troubleshoot --issue "connection-failures" --component "cartservice"
```

### Performance Issues Analysis
```bash
# CPU and performance analysis
kubectl top pods --sort-by=cpu
kubectl describe pod <pod-name> | grep -i throttl
kubectl get events --field-selector reason=FailedScheduling

# AI performance optimization
az aks ai-troubleshoot --issue "performance-degradation" --component "currencyservice"
```

## 🛠 Configuration Options

All demo issues are controlled via environment variables:

| Service | Variable | Purpose | Default |
|---------|----------|---------|---------|
| Recommendation | `ENABLE_MEMORY_LEAK` | Enable memory leak simulation | `false` |
| Cart | `SIMULATE_CONNECTION_ISSUES` | Enable connection failures | `false` |
| Cart | `CONNECTION_FAILURE_RATE` | Rate of connection failures | `0.3` |
| Currency | `SIMULATE_CPU_SPIKES` | Enable CPU spike simulation | `false` |
| Currency | `CPU_SPIKE_FREQUENCY` | Rate of CPU spikes | `0.1` |
| Payment | `SIMULATE_PAYMENT_DELAYS` | Enable payment delays | `false` |
| Payment | `PAYMENT_DELAY_FREQUENCY` | Rate of delayed payments | `0.3` |
| Ad | `SIMULATE_HEALTH_CHECK_FAILURES` | Enable health check failures | `false` |
| Ad | `HEALTH_CHECK_FAILURE_RATE` | Rate of health check failures | `0.2` |

## 🎯 Demo Scenarios

### Scenario 1: Memory Pressure Investigation
**Issue**: Gradual memory consumption in recommendation service
**AI Demo**: Show how AI correlates memory metrics, identifies memory leaks, and suggests optimization strategies

### Scenario 2: Intermittent Service Failures  
**Issue**: Random connection failures affecting user experience
**AI Demo**: Demonstrate AI's ability to trace network issues across service boundaries and suggest resilience improvements

### Scenario 3: Performance Degradation
**Issue**: CPU throttling causing response time increases
**AI Demo**: Show AI analysis of resource constraints and automated scaling recommendations

### Scenario 4: Cascading Failures
**Issue**: Payment timeouts causing checkout failures
**AI Demo**: Demonstrate root cause analysis across distributed systems and circuit breaker recommendations

### Scenario 5: Infrastructure Health
**Issue**: Pod restart loops due to health check failures
**AI Demo**: Show AI correlation of Kubernetes events with application health and remediation suggestions

## 🔧 Troubleshooting the Demo

### Common Issues

1. **Metrics not available**: Wait 2-3 minutes after deployment for metrics to appear
2. **Issues not triggering**: Ensure environment variables are set correctly
3. **Load generator not working**: Check frontend service is accessible

### Reset Demo Environment
```bash
# Remove all troubleshooting manifests
kubectl delete -f demo-troubleshooting-manifests/

# Restore clean state
kubectl apply -f kubernetes-manifests/

# Wait for stabilization
sleep 30
```

## 📊 Monitoring and Observability

### Key Metrics to Watch
- **Memory Usage**: `kubectl top pods --sort-by=memory`
- **CPU Usage**: `kubectl top pods --sort-by=cpu`  
- **Pod Restarts**: `kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses[0].restartCount`
- **Events**: `kubectl get events --sort-by='.firstTimestamp'`

### Log Analysis
```bash
# Service-specific logs
kubectl logs deployment/recommendationservice | grep -i memory
kubectl logs deployment/cartservice | grep -i connection
kubectl logs deployment/currencyservice | grep -i cpu
kubectl logs deployment/paymentservice | grep -i timeout
kubectl logs deployment/adservice | grep -i health
```

## 🎓 Learning Outcomes

This demo showcases:
- **Multi-service correlation**: How issues in one service affect others
- **Pattern recognition**: AI identifying common failure patterns
- **Root cause analysis**: Tracing problems to their source  
- **Automated remediation**: AI-suggested fixes and optimizations
- **Real-time troubleshooting**: Live issue detection and resolution
- **Kubernetes-native debugging**: Using K8s tools for troubleshooting

## 🤝 Contributing

This is a demo repository. For the original microservices-demo:
- **Original Repo**: https://github.com/GoogleCloudPlatform/microservices-demo
- **Issues**: Report issues with the base application to the original repo
- **Demo Issues**: For demo-specific problems, create issues in this repository

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Based on the [Google Cloud Platform microservices-demo](https://github.com/GoogleCloudPlatform/microservices-demo)
- Created for KubeCon AI troubleshooting demonstrations
- Designed to work with Azure Kubernetes Service (AKS) AI agents

---

**Perfect for**: KubeCon talks, AI troubleshooting demos, Kubernetes training, SRE education, and demonstrating modern observability practices.