import 'package:flutter/material.dart';
import 'package:geo_connect/screens/product_profile.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/refreshable_scaffold.dart';
import 'cart_screen.dart';
import 'notifications_screen.dart';
import 'map.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Stream<List<Map<String, dynamic>>> _productsStream;
  final _searchController = TextEditingController();
  String _searchText = '';
  Timer? _debounce;

  // --- REALTIME NOTIFICATIONS STATE ---
  List<Map<String, dynamic>> _notifications = [];
  RealtimeChannel? _notificationsChannel;

  @override
  void initState() {
    super.initState();
    _initProductsStream();
    _initRealtimeNotifications();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text;
      });
    });
  }

  void _initProductsStream() {
    _productsStream = Supabase.instance.client
        .from('products')
        .stream(primaryKey: ['id']).order('created_at', ascending: false);
  }

  /// Sets up a Supabase Realtime channel that listens for INSERT, UPDATE, and
  /// DELETE events on the `notifications` table, filtered server-side to the
  /// current user.  On every change the local [_notifications] list is updated
  /// so the unread badge reflects reality instantly — no polling needed.
  void _initRealtimeNotifications() {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Fetch the current snapshot so the badge is populated immediately.
    _fetchNotifications(userId);

    // 2. Subscribe to realtime changes.
    _notificationsChannel = Supabase.instance.client
        .channel('notifications:$userId')
        .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        // A new notification arrived — prepend it.
        final newRecord = payload.newRecord;
        if (newRecord.isNotEmpty) {
          setState(() {
            _notifications = [newRecord, ..._notifications];
          });
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        // A notification was updated (e.g. marked as read) — patch in place.
        final updated = payload.newRecord;
        if (updated.isNotEmpty) {
          setState(() {
            _notifications = _notifications.map((n) {
              return n['id'] == updated['id'] ? updated : n;
            }).toList();
          });
        }
      },
    )
        .onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        // A notification was deleted — remove it.
        final deletedId = payload.oldRecord['id'];
        if (deletedId != null) {
          setState(() {
            _notifications =
                _notifications.where((n) => n['id'] != deletedId).toList();
          });
        }
      },
    )
        .subscribe();
  }

  Future<void> _fetchNotifications(String userId) async {
    try {
      final data = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  /// Marks all unread notifications as read in Supabase.
  /// The realtime UPDATE listener above will automatically update [_notifications]
  /// so the badge clears without an extra setState call — but we also update
  /// locally for instant feedback.
  Future<void> _markAllNotificationsAsRead() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final hasUnread = _notifications.any((n) => n['is_read'] == false);
    if (!hasUnread) return;

    // Optimistic local update so the badge clears immediately.
    setState(() {
      _notifications = _notifications.map((n) {
        return n['is_read'] == false ? {...n, 'is_read': true} : n;
      }).toList();
    });

    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
      // Roll back the optimistic update on failure.
      final userId2 = Supabase.instance.client.auth.currentUser?.id;
      if (userId2 != null) _fetchNotifications(userId2);
    }
  }

  Future<void> _handleRefresh() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId != null) await _fetchNotifications(userId);
    await Future.delayed(const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    // Always unsubscribe the realtime channel to avoid memory leaks.
    _notificationsChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('DOKO',
                style: TextStyle(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Row(
              children: [
                // Cart Icon and Badge
                Consumer<CartProvider>(
                  builder: (context, cart, child) => Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_basket_outlined,
                            color: Colors.grey.shade700),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const CartScreen()),
                          );
                        },
                      ),
                      if (cart.itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            constraints:
                            const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              cart.itemCount.toString(),
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 10),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Notifications Icon and Badge (driven by realtime state)
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(Icons.notifications_outlined,
                          color: Colors.grey.shade700),
                      onPressed: () async {
                        // Navigate first so the user can SEE the notifications,
                        // then mark as read after the screen has opened.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const NotificationsScreen()),
                        ).then((_) {
                          // Mark as read when the user returns from the screen.
                          _markAllNotificationsAsRead();
                        });
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: RefreshableWrapper(
        onRefresh: _handleRefresh,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 20),
              const PromoBanner(),
              const SizedBox(height: 20),
              _buildSectionHeader('Browse Products', () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              }),
              const SizedBox(height: 10),
              _buildProductGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: () {
            /* TODO: Show filter options */
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onMapPressed) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(
          onPressed: onMapPressed,
          icon: const Icon(Icons.map_outlined, color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildProductGrid() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text('Error fetching products: ${snapshot.error}'));
        }
        final allProducts = snapshot.data;
        if (allProducts == null || allProducts.isEmpty) {
          return const Center(child: Text('No products available yet.'));
        }

        final filteredProducts = allProducts.where((product) {
          final productName = product['productName'] as String? ?? '';
          return productName.toLowerCase().contains(_searchText.toLowerCase());
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text('No products match your search.'));
        }

        return GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredProducts.length,
          itemBuilder: (context, index) {
            final product = filteredProducts[index];
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}

class PromoBanner extends StatelessWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Image.network(
        'https://clipart-library.com/2023/5f0d0ab64520712d29e2c2fd_NEW20Summer20Market20Logo20white.png',
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                'Summer Market',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        product['imageUrl'] as String? ?? 'https://i.imgur.com/S8A4L5p.png';
    final productId = (product['id'] as num?)?.toInt() ?? 0;
    final productName = product['productName'] as String? ?? 'No Name';
    final price = (product['price'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductProfilePage(product: product),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  SizedBox.expand(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image_not_supported,
                            size: 40, color: Colors.grey);
                      },
                    ),
                  ),
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white70,
                        shape: BoxShape.circle,
                      ),
                      child: Consumer<CartProvider>(
                        builder: (context, cart, child) {
                          final isAdded = cart.isItemInCart(productId);
                          return IconButton(
                            iconSize: 20,
                            icon: Icon(
                              isAdded ? Icons.favorite : Icons.favorite_border,
                              color: isAdded ? Colors.red : Colors.black54,
                            ),
                            onPressed: () {
                              try {
                                cart.toggleCartStatus(
                                    productId, productName, price, imageUrl);
                              } catch (e) {
                                debugPrint('Error toggling cart: $e');
                              }
                            },
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(6),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('Rs.${price.toStringAsFixed(2)}',
                      style:
                      TextStyle(color: Colors.grey.shade800, fontSize: 14)),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 16),
                      SizedBox(width: 4),
                      Text('4.5', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 4),
                      Text('(123)',
                          style:
                          TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}