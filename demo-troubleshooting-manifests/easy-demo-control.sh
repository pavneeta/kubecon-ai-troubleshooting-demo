# 🎯 KubeCon Sidecar Demo Control Script
# Easy control of sidecar-based issue simulation - no image rebuilds needed!

echo "🎯 KubeCon Sidecar Issue Demo Control"
echo "Using Google's original images + issue simulation sidecars"

show_menu() {
    echo ""
    echo "🧠 MEMORY ISSUES:"
    echo "1) Deploy Memory Leak Simulation (Recommendation Service)"
    echo ""
    echo "🌐 CONNECTION ISSUES:" 
    echo "2) Deploy Connection Issues (Cart Service)"
    echo ""
    echo "💳 TIMEOUT ISSUES:"
    echo "3) Deploy Payment Delays (Payment Service)"
    echo ""
    echo "⚡ CPU ISSUES:"
    echo "4) Enable CPU Spikes (via env var toggle)"
    echo ""
    echo "🔄 CONTROL:"
    echo "5) Reset All Services to Normal"
    echo "6) Show Current Issues Status"
    echo "7) Exit"
    echo ""
}

# Function to deploy memory leak simulation
deploy_memory_leak() {
    echo "🧠 Deploying Memory Leak Simulation..."
    kubectl apply -f demo-troubleshooting-manifests/recommendationservice-memory-leak.yaml
    echo ""
    echo "✅ Memory leak sidecar deployed!"
    echo "📊 Monitor with:"
    echo "   kubectl top pods | grep recommendation"
    echo "   kubectl logs deployment/recommendationservice -c issue-simulator"
    echo ""
    echo "🎯 The sidecar will allocate 10MB every 5 seconds until OOM"
}

# Function to deploy connection issues
deploy_connection_issues() {
    echo "🌐 Deploying Connection Issues Simulation..."
    kubectl apply -f demo-troubleshooting-manifests/cartservice-sidecar-issues.yaml
    echo ""
    echo "✅ Connection chaos sidecar deployed!"
    echo "📊 Monitor with:"
    echo "   kubectl logs deployment/cartservice -c connection-chaos"
    echo "   kubectl get pods | grep cart"
    echo ""
    echo "🎯 The sidecar simulates intermittent Redis connection failures"
}

# Function to deploy payment delays
deploy_payment_delays() {
    echo "💳 Deploying Payment Delay Simulation..."
    kubectl apply -f demo-troubleshooting-manifests/paymentservice-sidecar-issues.yaml
    echo ""
    echo "✅ Payment delay sidecar deployed!"
    echo "📊 Monitor with:"
    echo "   kubectl logs deployment/paymentservice -c payment-delay-simulator"
    echo "   kubectl logs deployment/checkoutservice | grep -i payment"
    echo ""
    echo "🎯 The sidecar adds 5-15 second delays to payment processing"
}

# Function to enable CPU spikes
enable_cpu_spikes() {
    echo "⚡ Enabling CPU Spikes in Recommendation Service..."
    kubectl patch deployment recommendationservice -p '{
        "spec": {
            "template": {
                "spec": {
                    "containers": [{
                        "name": "issue-simulator",
                        "env": [
                            {"name": "ENABLE_MEMORY_LEAK", "value": "false"},
                            {"name": "SIMULATE_CPU_SPIKES", "value": "true"},
                            {"name": "SIMULATE_CONNECTION_ISSUES", "value": "false"}
                        ]
                    }]
                }
            }
        }
    }' || echo "Deploy memory leak manifest first!"
    echo ""
    echo "✅ CPU spikes enabled!"
    echo "📊 Monitor with:"
    echo "   kubectl top pods | grep recommendation"
    echo "   kubectl logs deployment/recommendationservice -c issue-simulator"
    echo ""
    echo "🎯 The sidecar will create 15-second CPU bursts every 30 seconds"
}

# Function to reset all services
reset_all_services() {
    echo "� Resetting All Services to Normal..."
    echo ""
    
    echo "↻ Restoring recommendation service..."
    kubectl apply -f kubernetes-manifests/recommendationservice.yaml
    
    echo "↻ Restoring cart service..."
    kubectl apply -f kubernetes-manifests/cartservice.yaml
    
    echo "↻ Restoring payment service..."
    kubectl apply -f kubernetes-manifests/paymentservice.yaml
    
    echo ""
    echo "✅ All services restored to normal Google images!"
    echo "📊 Monitor restoration:"
    echo "   kubectl get pods"
    echo "   kubectl top pods"
}

# Function to show current status
show_current_status() {
    echo "📊 Current Demo Status:"
    echo ""
    
    echo "🔍 Active Pods:"
    kubectl get pods | grep -E "(recommendation|cart|payment)"
    echo ""
    
    echo "💾 Resource Usage:"
    kubectl top pods | grep -E "(recommendation|cart|payment)" || echo "Metrics not available yet"
    echo ""
    
    echo "🏷️  Deployed Issues (check labels):"
    kubectl get deployments -l demo-issue --show-labels || echo "No demo issues currently deployed"
    echo ""
    
    echo "📋 Recent Events:"
    kubectl get events --sort-by=.firstTimestamp | tail -5
}

# Main menu loop
while true; do
    show_menu
    read -p "Select option [1-7]: " choice
    
    case $choice in
        1) deploy_memory_leak ;;
        2) deploy_connection_issues ;;
        3) deploy_payment_delays ;;
        4) enable_cpu_spikes ;;
        5) reset_all_services ;;
        6) show_current_status ;;
        7) echo "🎪 Demo complete! Goodbye! 👋"; exit 0 ;;
        *) echo "❌ Invalid option. Please try again." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
done