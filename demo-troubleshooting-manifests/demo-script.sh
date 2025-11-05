#!/bin/bash

# KubeCon AI Troubleshooting Demo Script
# This script helps orchestrate the demonstration of application layer issues

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-default}
SLEEP_TIME=${SLEEP_TIME:-30}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

wait_for_deployment() {
    local deployment=$1
    print_info "Waiting for deployment $deployment to be ready..."
    kubectl rollout status deployment/$deployment -n $NAMESPACE --timeout=300s
}

check_pod_status() {
    local app=$1
    echo -e "${BLUE}Pod Status for $app:${NC}"
    kubectl get pods -l app=$app -n $NAMESPACE -o wide
    echo ""
}

show_resource_usage() {
    local app=$1
    echo -e "${BLUE}Resource Usage for $app:${NC}"
    kubectl top pods -l app=$app -n $NAMESPACE 2>/dev/null || echo "Metrics not available yet"
    echo ""
}

show_events() {
    local app=$1
    echo -e "${BLUE}Recent Events for $app:${NC}"
    kubectl get events -n $NAMESPACE --field-selector involvedObject.name=$(kubectl get pods -l app=$app -n $NAMESPACE -o name | head -1 | cut -d'/' -f2) --sort-by='.firstTimestamp' | tail -5
    echo ""
}

demo_memory_leak() {
    print_header "Demo 1: Memory Leak in Recommendation Service"
    
    print_info "Deploying recommendation service with memory leak simulation..."
    kubectl apply -f demo-troubleshooting-manifests/recommendationservice-memory-leak.yaml -n $NAMESPACE
    
    wait_for_deployment "recommendationservice"
    
    print_info "Monitoring memory usage (this will show gradual increase)..."
    for i in {1..5}; do
        echo -e "${YELLOW}Check #$i:${NC}"
        check_pod_status "recommendationservice"
        show_resource_usage "recommendationservice"
        
        # Generate some load to trigger memory leak
        print_info "Generating load to trigger memory leak..."
        kubectl exec -n $NAMESPACE deployment/loadgenerator -- curl -s http://frontend/product/OLJCESPC7Z > /dev/null || true
        
        sleep $SLEEP_TIME
    done
    
    print_warning "Watch for OOMKilled events and memory usage patterns"
    show_events "recommendationservice"
}

demo_connection_issues() {
    print_header "Demo 2: Database Connection Issues in Cart Service"
    
    print_info "Deploying cart service with connection issue simulation..."
    kubectl apply -f demo-troubleshooting-manifests/cartservice-connection-issues.yaml -n $NAMESPACE
    
    wait_for_deployment "cartservice"
    
    print_info "Testing cart operations (expect some failures)..."
    for i in {1..3}; do
        echo -e "${YELLOW}Test #$i:${NC}"
        check_pod_status "cartservice"
        
        # Show recent logs with connection issues
        echo -e "${BLUE}Recent Cart Service Logs:${NC}"
        kubectl logs deployment/cartservice -n $NAMESPACE --tail=10 | grep -E "(connection|retry|timeout|error)" || true
        
        sleep 15
    done
    
    show_events "cartservice"
}

demo_cpu_spikes() {
    print_header "Demo 3: CPU Spikes in Currency Service"
    
    print_info "Deploying currency service with CPU spike simulation..."
    kubectl apply -f demo-troubleshooting-manifests/currencyservice-cpu-spikes.yaml -n $NAMESPACE
    
    wait_for_deployment "currencyservice"
    
    print_info "Monitoring CPU usage and generating load..."
    for i in {1..4}; do
        echo -e "${YELLOW}CPU Check #$i:${NC}"
        check_pod_status "currencyservice"
        show_resource_usage "currencyservice"
        
        # Generate currency conversion requests
        kubectl exec -n $NAMESPACE deployment/loadgenerator -- curl -s http://frontend/ > /dev/null || true
        
        sleep 20
    done
    
    print_warning "Watch for CPU throttling and performance degradation"
    show_events "currencyservice"
}

demo_grpc_timeouts() {
    print_header "Demo 4: gRPC Timeout Issues in Payment Service"
    
    print_info "Deploying payment service with timeout simulation..."
    kubectl apply -f demo-troubleshooting-manifests/paymentservice-timeout-issues.yaml -n $NAMESPACE
    
    wait_for_deployment "paymentservice"
    
    print_info "Testing payment processing (expect timeouts)..."
    for i in {1..3}; do
        echo -e "${YELLOW}Payment Test #$i:${NC}"
        check_pod_status "paymentservice"
        
        echo -e "${BLUE}Recent Payment Service Logs:${NC}"
        kubectl logs deployment/paymentservice -n $NAMESPACE --tail=15 | grep -E "(delay|timeout|error)" || true
        
        sleep 20
    done
    
    show_events "paymentservice"
}

demo_health_check_failures() {
    print_header "Demo 5: Health Check Failures in Ad Service"
    
    print_info "Deploying ad service with health check failure simulation..."
    kubectl apply -f demo-troubleshooting-manifests/adservice-health-failures.yaml -n $NAMESPACE
    
    wait_for_deployment "adservice"
    
    print_info "Monitoring health check status..."
    for i in {1..4}; do
        echo -e "${YELLOW}Health Check #$i:${NC}"
        check_pod_status "adservice"
        
        echo -e "${BLUE}Health Check Status:${NC}"
        kubectl describe pods -l app=adservice -n $NAMESPACE | grep -E "(Readiness|Liveness|Ready)" || true
        
        echo -e "${BLUE}Recent Ad Service Logs:${NC}"
        kubectl logs deployment/adservice -n $NAMESPACE --tail=10 | grep -i health || true
        
        sleep 25
    done
    
    show_events "adservice"
}

cleanup_demo() {
    print_header "Cleaning Up Demo Environment"
    
    print_info "Removing problematic deployments..."
    kubectl delete -f demo-troubleshooting-manifests/ -n $NAMESPACE --ignore-not-found=true
    
    print_info "Restoring normal services..."
    kubectl apply -f kubernetes-manifests/ -n $NAMESPACE
    
    print_info "Waiting for services to stabilize..."
    sleep 30
    
    print_info "Demo cleanup complete!"
}

show_ai_troubleshooting_commands() {
    print_header "AI Troubleshooting Commands Reference"
    
    cat << EOF
Use these commands with your AKS AI agent to analyze the issues:

${GREEN}Memory Issues:${NC}
az aks kollect --resource-group <rg> --name <cluster>
kubectl top pods --sort-by=memory
kubectl describe pod <pod-name> | grep -A 10 -B 10 OOMKilled

${GREEN}Connection Issues:${NC}
kubectl logs deployment/cartservice | grep -E "connection|timeout|retry"
kubectl get endpoints redis-cart
kubectl describe svc redis-cart

${GREEN}CPU Issues:${NC}
kubectl top pods --sort-by=cpu
kubectl describe pod <pod-name> | grep -i throttl
kubectl get events --field-selector reason=FailedScheduling

${GREEN}Timeout Issues:${NC}
kubectl logs deployment/checkoutservice | grep -i deadline
kubectl logs deployment/paymentservice | grep -E "delay|timeout"

${GREEN}Health Check Issues:${NC}
kubectl get pods -w | grep adservice
kubectl describe pod <pod-name> | grep -E "Readiness|Liveness"
kubectl get events --field-selector reason=Unhealthy

${GREEN}General Diagnostics:${NC}
kubectl get events --sort-by='.firstTimestamp'
kubectl describe nodes | grep -E "Pressure|Condition"
kubectl top nodes
EOF
}

# Main menu
main_menu() {
    while true; do
        print_header "KubeCon AI Troubleshooting Demo"
        echo "1) Deploy Memory Leak Demo"
        echo "2) Deploy Connection Issues Demo"
        echo "3) Deploy CPU Spikes Demo"
        echo "4) Deploy gRPC Timeout Demo"
        echo "5) Deploy Health Check Failures Demo"
        echo "6) Show AI Troubleshooting Commands"
        echo "7) Run All Demos Sequentially"
        echo "8) Cleanup Demo Environment"
        echo "9) Exit"
        echo ""
        
        read -p "Select an option (1-9): " choice
        
        case $choice in
            1) demo_memory_leak ;;
            2) demo_connection_issues ;;
            3) demo_cpu_spikes ;;
            4) demo_grpc_timeouts ;;
            5) demo_health_check_failures ;;
            6) show_ai_troubleshooting_commands ;;
            7) 
                demo_memory_leak
                sleep 60
                demo_connection_issues
                sleep 60
                demo_cpu_spikes
                sleep 60
                demo_grpc_timeouts
                sleep 60
                demo_health_check_failures
                ;;
            8) cleanup_demo ;;
            9) print_info "Exiting demo script"; exit 0 ;;
            *) print_error "Invalid option. Please select 1-9." ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl not found. Please install kubectl."
        exit 1
    fi
    
    if ! kubectl cluster-info &> /dev/null; then
        print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
        exit 1
    fi
    
    if ! kubectl get namespace $NAMESPACE &> /dev/null; then
        print_warning "Namespace $NAMESPACE not found. Creating..."
        kubectl create namespace $NAMESPACE
    fi
    
    print_info "Prerequisites check passed!"
}

# Script execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    check_prerequisites
    main_menu
fi