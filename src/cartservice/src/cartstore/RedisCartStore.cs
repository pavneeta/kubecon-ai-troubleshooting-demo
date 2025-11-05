// Copyright 2018 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System;
using System.Linq;
using System.Threading.Tasks;
using System.Threading;
using Grpc.Core;
using Microsoft.Extensions.Caching.Distributed;
using Google.Protobuf;

namespace cartservice.cartstore
{
    public class RedisCartStore : ICartStore
    {
        private readonly IDistributedCache _cache;
        private readonly Random _random;
        private readonly bool _simulateConnectionIssues;
        private readonly double _failureRate;
        private readonly int _maxRetries;
        private readonly int _baseDelayMs;

        public RedisCartStore(IDistributedCache cache)
        {
            _cache = cache;
            _random = new Random();
            
            // Connection issue simulation controlled by environment variables
            _simulateConnectionIssues = Environment.GetEnvironmentVariable("SIMULATE_CONNECTION_ISSUES")?.ToLower() == "true";
            _failureRate = double.TryParse(Environment.GetEnvironmentVariable("CONNECTION_FAILURE_RATE"), out double rate) ? rate : 0.3;
            _maxRetries = int.TryParse(Environment.GetEnvironmentVariable("MAX_CONNECTION_RETRIES"), out int retries) ? retries : 3;
            _baseDelayMs = int.TryParse(Environment.GetEnvironmentVariable("BASE_RETRY_DELAY_MS"), out int delay) ? delay : 100;
            
            Console.WriteLine($"RedisCartStore initialized - Connection issues: {_simulateConnectionIssues}, " +
                            $"Failure rate: {_failureRate}, Max retries: {_maxRetries}, Base delay: {_baseDelayMs}ms");
        }

        private async Task<T> ExecuteWithRetryAsync<T>(Func<Task<T>> operation, string operationName)
        {
            int attempts = 0;
            Exception lastException = null;

            while (attempts <= _maxRetries)
            {
                try
                {
                    // Simulate connection issues if enabled
                    if (_simulateConnectionIssues && attempts == 0)
                    {
                        if (_random.NextDouble() < _failureRate)
                        {
                            // Simulate different types of connection issues
                            var issueType = _random.Next(1, 4);
                            switch (issueType)
                            {
                                case 1:
                                    throw new TimeoutException($"Redis connection timeout during {operationName}");
                                case 2:
                                    throw new System.Net.Sockets.SocketException(10060); // Connection timeout
                                case 3:
                                    throw new InvalidOperationException($"Redis connection pool exhausted during {operationName}");
                            }
                        }
                        
                        // Simulate slow connections occasionally
                        if (_random.NextDouble() < 0.1) // 10% chance of slow operation
                        {
                            Console.WriteLine($"Simulating slow Redis operation for {operationName}");
                            await Task.Delay(_random.Next(1000, 3000)); // 1-3 second delay
                        }
                    }

                    return await operation();
                }
                catch (Exception ex)
                {
                    lastException = ex;
                    attempts++;
                    
                    if (attempts <= _maxRetries)
                    {
                        var delayMs = _baseDelayMs * (int)Math.Pow(2, attempts - 1); // Exponential backoff
                        Console.WriteLine($"Redis operation {operationName} failed (attempt {attempts}), retrying in {delayMs}ms: {ex.Message}");
                        await Task.Delay(delayMs);
                    }
                }
            }

            Console.WriteLine($"Redis operation {operationName} failed after {attempts} attempts");
            throw new RpcException(new Status(StatusCode.Unavailable, 
                $"Can't access cart storage after {attempts} attempts. Last error: {lastException?.Message}"));
        }

        public async Task AddItemAsync(string userId, string productId, int quantity)
        {
            Console.WriteLine($"AddItemAsync called with userId={userId}, productId={productId}, quantity={quantity}");

            await ExecuteWithRetryAsync(async () =>
            {
                Hipstershop.Cart cart;
                var value = await _cache.GetAsync(userId);
                if (value == null)
                {
                    cart = new Hipstershop.Cart();
                    cart.UserId = userId;
                    cart.Items.Add(new Hipstershop.CartItem { ProductId = productId, Quantity = quantity });
                }
                else
                {
                    cart = Hipstershop.Cart.Parser.ParseFrom(value);
                    var existingItem = cart.Items.SingleOrDefault(i => i.ProductId == productId);
                    if (existingItem == null)
                    {
                        cart.Items.Add(new Hipstershop.CartItem { ProductId = productId, Quantity = quantity });
                    }
                    else
                    {
                        existingItem.Quantity += quantity;
                    }
                }
                await _cache.SetAsync(userId, cart.ToByteArray());
                return true; // Success indicator for ExecuteWithRetryAsync
            }, "AddItem");
        }

        public async Task EmptyCartAsync(string userId)
        {
            Console.WriteLine($"EmptyCartAsync called with userId={userId}");

            await ExecuteWithRetryAsync(async () =>
            {
                var cart = new Hipstershop.Cart();
                await _cache.SetAsync(userId, cart.ToByteArray());
                return true; // Success indicator for ExecuteWithRetryAsync
            }, "EmptyCart");
        }

        public async Task<Hipstershop.Cart> GetCartAsync(string userId)
        {
            Console.WriteLine($"GetCartAsync called with userId={userId}");

            return await ExecuteWithRetryAsync(async () =>
            {
                // Access the cart from the cache
                var value = await _cache.GetAsync(userId);

                if (value != null)
                {
                    return Hipstershop.Cart.Parser.ParseFrom(value);
                }

                // We decided to return empty cart in cases when user wasn't in the cache before
                return new Hipstershop.Cart();
            }, "GetCart");
        }

        public bool Ping()
        {
            try
            {
                return true;
            }
            catch (Exception)
            {
                return false;
            }
        }
    }
}
