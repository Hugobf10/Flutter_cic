import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../app/ui/app_components.dart';
import '../../app/screens/document_viewer_screen.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../services/app_permission_service.dart';
import '../../services/attachment_service.dart';
import '../../services/native_ocr_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/purchases_api_service.dart';
import '../../theme/app_theme.dart';
import 'barcode_scanner_screen.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});

  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.uiText('Compras', 'Purchases'),
      padding: EdgeInsets.zero,
      actions: const [_PurchasesRefreshButton()],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: context.uiText('Productos', 'Products')),
                Tab(text: context.uiText('Pedidos', 'Orders')),
                Tab(text: context.uiText('Recepción', 'Receipt')),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _ProductsTab(),
                _PurchaseOrdersTab(),
                _ReceptionTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchasesRefreshButton extends StatelessWidget {
  const _PurchasesRefreshButton();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class _ProductsTab extends StatefulWidget {
  const _ProductsTab();

  @override
  State<_ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<_ProductsTab> {
  final OdooService _odoo = OdooService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load([String query = '']) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final domain = query.trim().isEmpty
          ? const []
          : [
              '|',
              '|',
              ['name', 'ilike', query.trim()],
              ['default_code', 'ilike', query.trim()],
              ['barcode', 'ilike', query.trim()],
            ];
      final rows = OdooService.sessionIsInternal(_odoo.sessionInfo) == true
          ? (OdooValues.map(
                      await _purchasesApi.bootstrap(query: query),
                    )['products']
                    as List? ??
                const [])
          : await _odoo.searchRead(
              'product.template',
              domain: domain,
              fields: const [
                'name',
                'default_code',
                'barcode',
                'list_price',
                'standard_price',
                'purchase_ok',
                'uom_id',
                'uom_po_id',
                'product_variant_id',
              ],
              order: 'write_date desc',
              limit: 60,
            );
      _products = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _scanSearch() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    _searchCtrl.text = code;
    await _load(code);
  }

  Future<void> _openCreateProduct() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _ProductFormScreen(),
      ),
    );
    if (created == true) await _load(_searchCtrl.text);
  }

  Future<void> _openEditProduct(Map<String, dynamic> product) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _ProductFormScreen(product: product),
      ),
    );
    if (updated == true) await _load(_searchCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return RefreshIndicator(
      onRefresh: () => _load(_searchCtrl.text),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  controller: _searchCtrl,
                  hintText: context.uiText(
                    'Buscar producto, referencia o código...',
                    'Search product, reference or code...',
                  ),
                  onSubmitted: _load,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _scanSearch,
                icon: Icon(Icons.qr_code_scanner_rounded),
                tooltip: context.uiText('Escanear código', 'Scan code'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (auth.canEditModule('purchases')) ...[
            AppButton.primary(
              label: context.uiText('Nuevo producto', 'New product'),
              icon: Icons.add_rounded,
              onPressed: _openCreateProduct,
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 6),
          if (_loading)
            SizedBox(
              height: 260,
              child: AppLoadingView(
                label: context.uiText(
                  'Cargando productos...',
                  'Loading products...',
                ),
              ),
            )
          else if (_error != null)
            AppEmptyState(
              title: context.uiText(
                'No se pudieron cargar productos',
                'Could not load products',
              ),
              subtitle: _error!,
              icon: Icons.lock_outline_rounded,
              action: AppButton.outline(
                label: context.uiText('Reintentar', 'Retry'),
                icon: Icons.refresh_rounded,
                onPressed: () => _load(_searchCtrl.text),
              ),
            )
          else if (_products.isEmpty)
            AppEmptyState(
              title: context.uiText(
                'Sin productos visibles',
                'No visible products',
              ),
              subtitle: context.uiText(
                'Busca por nombre, referencia o código de barras.',
                'Search by name, reference or barcode.',
              ),
              icon: Icons.inventory_2_outlined,
            )
          else ...[
            AppSectionHeader(
              title: context.uiText(
                '${_products.length} productos',
                '${_products.length} products',
              ),
            ),
            ..._products.map(
              (product) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ProductCard(
                  product: product,
                  onTap: auth.canEditModule('purchases')
                      ? () => _openEditProduct(product)
                      : null,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, this.onTap});

  final Map<String, dynamic> product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ref = (product['default_code'] ?? '').toString();
    final barcode = (product['barcode'] ?? '').toString();
    final price = product['list_price'];
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(Icons.inventory_2_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product['name'] ?? 'Producto').toString(),
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (ref.isNotEmpty) 'Ref. $ref',
                    if (barcode.isNotEmpty) 'EAN $barcode',
                    if (price != null) '${_num(price).toStringAsFixed(2)} €',
                  ].join(' · '),
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: product['purchase_ok'] == true ? 'Comprable' : 'Interno',
            color: product['purchase_ok'] == true
                ? AppTheme.success
                : AppTheme.textMutedFor(context),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppTheme.textMutedFor(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProductFormScreen extends StatefulWidget {
  const _ProductFormScreen({this.product});

  final Map<String, dynamic>? product;

  @override
  State<_ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<_ProductFormScreen> {
  final OdooService _odoo = OdooService();
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _refCtrl = TextEditingController();
  final _barcodeCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  bool _saving = false;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    if (product != null) {
      _nameCtrl.text = (product['name'] ?? '').toString();
      _refCtrl.text = (product['default_code'] ?? '').toString();
      _barcodeCtrl.text = (product['barcode'] ?? '').toString();
      final price = _num(product['list_price']);
      final cost = _num(product['standard_price']);
      if (price > 0) _priceCtrl.text = _formatQty(price);
      if (cost > 0) _costCtrl.text = _formatQty(cost);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _refCtrl.dispose();
    _barcodeCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (code == null || code.isEmpty) return;
    setState(() => _barcodeCtrl.text = code);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'El nombre del producto es obligatorio.',
              'Product name is required.',
            ),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'name': _nameCtrl.text.trim(),
        'purchase_ok': true,
        'sale_ok': false,
        if (_refCtrl.text.trim().isNotEmpty)
          'default_code': _refCtrl.text.trim(),
        if (_barcodeCtrl.text.trim().isNotEmpty)
          'barcode': _barcodeCtrl.text.trim(),
        if (_priceCtrl.text.trim().isNotEmpty)
          'list_price': _parseDecimal(_priceCtrl.text),
        if (_costCtrl.text.trim().isNotEmpty)
          'standard_price': _parseDecimal(_costCtrl.text),
      };
      if (_isEditing) {
        // The purchase API returns product.product variants. Product master
        // data must be written on product.template, never on the variant id.
        final id =
            OdooValues.many2oneId(widget.product!['product_tmpl_id']) ??
            OdooValues.intValue(widget.product!['id']);
        if (id == null) {
          throw StateError(
            context.uiText(
              'Producto sin plantilla asociada.',
              'Product has no linked template.',
            ),
          );
        }
        await _odoo.write('product.template', id, payload);
      } else {
        await _odoo.create('product.template', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? context.uiText('Producto actualizado.', 'Product updated.')
                : context.uiText('Producto creado.', 'Product created.'),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.uiText('No se pudo guardar', 'Could not save')}: ${OdooService.prettyError(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing
          ? context.uiText('Editar producto', 'Edit product')
          : context.uiText('Nuevo producto', 'New product'),
      actions: [
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded),
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            AppSectionHeader(
              title: context.uiText('Nuevo producto', 'New product'),
              subtitle: context.uiText(
                'Crea la ficha básica de compra en Odoo.',
                'Create the basic purchase record in Odoo.',
              ),
            ),
            AppInput(
              controller: _nameCtrl,
              labelText: context.uiText('Nombre', 'Name'),
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 10),
            AppInput(
              controller: _refCtrl,
              labelText: context.uiText(
                'Referencia interna',
                'Internal reference',
              ),
              prefixIcon: Icons.tag_rounded,
            ),
            const SizedBox(height: 10),
            AppInput(
              controller: _barcodeCtrl,
              labelText: context.uiText('Código de barras', 'Barcode'),
              prefixIcon: Icons.qr_code_2_rounded,
              suffixIcon: IconButton(
                onPressed: _scanBarcode,
                icon: Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _costCtrl,
                    labelText: context.uiText('Coste', 'Cost'),
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.euro_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppInput(
                    controller: _priceCtrl,
                    labelText: context.uiText('Precio', 'Price'),
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.sell_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppButton.primary(
              label: _isEditing
                  ? context.uiText('Guardar cambios', 'Save changes')
                  : context.uiText('Crear producto', 'Create product'),
              icon: Icons.check_rounded,
              loading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _PurchaseOrdersTab extends StatefulWidget {
  const _PurchaseOrdersTab();

  @override
  State<_PurchaseOrdersTab> createState() => _PurchaseOrdersTabState();
}

class _PurchaseOrdersTabState extends State<_PurchaseOrdersTab> {
  final OdooService _odoo = OdooService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = OdooService.sessionIsInternal(_odoo.sessionInfo) == true
          ? ((await _purchasesApi.bootstrap())['orders'] as List? ?? const [])
          : await _odoo.searchRead(
              'purchase.order',
              fields: const [
                'name',
                'partner_id',
                'state',
                'date_order',
                'amount_total',
              ],
              order: 'date_order desc, id desc',
              limit: 80,
            );
      _orders = rows.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _openCreateOrder() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const _CreatePurchaseOrderScreen(),
      ),
    );
    if (created == true) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          if (auth.canEditModule('purchases')) ...[
            AppButton.primary(
              label: context.uiText(
                'Nuevo pedido de compra',
                'New purchase order',
              ),
              icon: Icons.add_shopping_cart_rounded,
              onPressed: _openCreateOrder,
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 6),
          if (_loading)
            SizedBox(
              height: 260,
              child: AppLoadingView(
                label: context.uiText(
                  'Cargando pedidos...',
                  'Loading orders...',
                ),
              ),
            )
          else if (_error != null)
            AppEmptyState(
              title: context.uiText(
                'No se pudieron cargar pedidos',
                'Could not load orders',
              ),
              subtitle: _error!,
              icon: Icons.shopping_cart_outlined,
              action: AppButton.outline(
                label: context.uiText('Reintentar', 'Retry'),
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            )
          else if (_orders.isEmpty)
            AppEmptyState(
              title: context.uiText(
                'Sin pedidos visibles',
                'No visible orders',
              ),
              subtitle: context.uiText(
                'No hay pedidos de compra disponibles para este usuario.',
                'There are no purchase orders available to this user.',
              ),
              icon: Icons.receipt_long_outlined,
            )
          else ...[
            AppSectionHeader(
              title: context.uiText(
                '${_orders.length} pedidos recientes',
                '${_orders.length} recent orders',
              ),
            ),
            ..._orders.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _OrderHeader(
                  order: order,
                  onTap: () {
                    final id = OdooValues.intValue(order['id']);
                    if (id == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => _PurchaseOrderDetailScreen(orderId: id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CreatePurchaseOrderScreen extends StatefulWidget {
  const _CreatePurchaseOrderScreen();

  @override
  State<_CreatePurchaseOrderScreen> createState() =>
      _CreatePurchaseOrderScreenState();
}

class _CreatePurchaseOrderScreenState
    extends State<_CreatePurchaseOrderScreen> {
  final OdooService _odoo = OdooService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _suppliers = [];
  List<Map<String, dynamic>> _products = [];
  int? _supplierId;
  final List<_DraftPurchaseLine> _lines = [];

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final purchaseBootstrap =
          OdooService.sessionIsInternal(_odoo.sessionInfo) == true
          ? await _purchasesApi.bootstrap()
          : const <String, dynamic>{};
      final suppliers = purchaseBootstrap.isNotEmpty
          ? (purchaseBootstrap['suppliers'] as List? ?? const [])
          : await _odoo.searchRead(
              'res.partner',
              domain: [
                ['supplier_rank', '>', 0],
                ['active', '=', true],
              ],
              fields: const ['name', 'commercial_partner_id'],
              order: 'name',
              limit: 120,
            );
      final products = purchaseBootstrap.isNotEmpty
          ? (purchaseBootstrap['products'] as List? ?? const [])
          : await _odoo.searchRead(
              'product.product',
              domain: [
                ['purchase_ok', '=', true],
                ['active', '=', true],
              ],
              fields: const [
                'name',
                'default_code',
                'barcode',
                'list_price',
                'standard_price',
                'product_tmpl_id',
                'uom_id',
                'uom_po_id',
              ],
              order: 'name',
              limit: 200,
            );
      _suppliers = suppliers
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _products = products
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (_suppliers.isNotEmpty) {
        _supplierId = OdooValues.intValue(_suppliers.first['id']);
      }
      if (_products.isNotEmpty) {
        _lines
          ..clear()
          ..add(
            _DraftPurchaseLine(
              productId: OdooValues.intValue(_products.first['id']) ?? 0,
            ),
          );
      }
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _addLine() {
    if (_products.isEmpty) return;
    setState(() {
      _lines.add(
        _DraftPurchaseLine(
          productId: OdooValues.intValue(_products.first['id']) ?? 0,
        ),
      );
    });
  }

  void _removeLine(_DraftPurchaseLine line) {
    if (_lines.length == 1) return;
    setState(() => _lines.remove(line));
  }

  Future<void> _save() async {
    if (_supplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText('Selecciona un proveedor.', 'Select a supplier.'),
          ),
        ),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'Añade al menos una línea.',
              'Add at least one line.',
            ),
          ),
        ),
      );
      return;
    }
    final orderLines = <dynamic>[];
    final apiLines = <Map<String, dynamic>>[];
    final invalidLines = <String>[];
    for (final line in _lines) {
      final matches = _products
          .where((p) => OdooValues.intValue(p['id']) == line.productId)
          .toList();
      if (matches.isEmpty) {
        invalidLines.add(
          context.uiText('producto no disponible', 'product unavailable'),
        );
        continue;
      }
      final product = matches.first;
      final variantId = OdooValues.intValue(product['id']);
      final uomId =
          OdooValues.many2oneId(product['uom_po_id']) ??
          OdooValues.many2oneId(product['uom_id']);
      final productName = OdooValues.string(
        product['name'],
        fallback: 'Producto',
      );
      if (variantId == null || uomId == null) {
        invalidLines.add(
          '$productName ${context.uiText('sin unidad de compra', 'without purchase unit')}',
        );
        continue;
      }
      if (line.qty <= 0 || line.price < 0) {
        invalidLines.add(
          '$productName ${context.uiText('con cantidad o precio inválido', 'with invalid quantity or price')}',
        );
        continue;
      }
      orderLines.add([
        0,
        0,
        {
          'product_id': variantId,
          'name': productName,
          'product_qty': line.qty,
          'price_unit': line.price,
          'product_uom': uomId,
          'date_planned': _formatOdooDateTime(
            DateTime.now().add(const Duration(days: 1)),
          ),
        },
      ]);
      apiLines.add({
        'product_id': variantId,
        'quantity': line.qty,
        'price_unit': line.price,
        'date_planned': _formatOdooDateTime(
          DateTime.now().add(const Duration(days: 1)),
        ),
      });
    }
    if (orderLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            invalidLines.isEmpty
                ? context.uiText(
                    'No hay líneas válidas para crear el pedido.',
                    'There are no valid lines to create the order.',
                  )
                : '${context.uiText('Revisa las líneas', 'Review the lines')}: ${invalidLines.join(', ')}.',
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (OdooService.sessionIsInternal(_odoo.sessionInfo) == true) {
        await _purchasesApi.createOrder(
          supplierId: _supplierId!,
          lines: apiLines,
        );
      } else {
        await _odoo.create('purchase.order', {
          'partner_id': _supplierId,
          'order_line': orderLines,
        });
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'Pedido de compra creado en borrador.',
              'Purchase order created as a draft.',
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.uiText('No se pudo crear el pedido', 'Could not create the order')}: ${OdooService.prettyError(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: context.uiText('Nuevo pedido de compra', 'New purchase order'),
      actions: [
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: Icon(Icons.close_rounded),
        ),
      ],
      child: _loading
          ? AppLoadingView(
              label: context.uiText(
                'Cargando opciones...',
                'Loading options...',
              ),
            )
          : _error != null
          ? AppEmptyState(
              title: context.uiText(
                'No se pudo preparar el pedido',
                'Could not prepare the order',
              ),
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : ListView(
              children: [
                AppSectionHeader(
                  title: context.uiText('Pedido en borrador', 'Draft order'),
                  subtitle: context.uiText(
                    'Selecciona proveedor y añade las líneas de compra.',
                    'Select a supplier and add purchase lines.',
                  ),
                ),
                DropdownButtonFormField<int>(
                  initialValue: _supplierId,
                  items: _suppliers
                      .map(
                        (supplier) => DropdownMenuItem<int>(
                          value: OdooValues.intValue(supplier['id']),
                          child: Text(
                            OdooValues.string(
                              supplier['name'],
                              fallback: 'Proveedor',
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _supplierId = value),
                  decoration: InputDecoration(
                    labelText: context.uiText('Proveedor', 'Supplier'),
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                AppSectionHeader(title: context.uiText('Líneas', 'Lines')),
                ..._lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _DraftPurchaseLineCard(
                      line: line,
                      products: _products,
                      onRemove: () => _removeLine(line),
                    ),
                  );
                }),
                const SizedBox(height: 8),
                AppButton.outline(
                  label: context.uiText('Añadir línea', 'Add line'),
                  icon: Icons.add_rounded,
                  onPressed: _addLine,
                ),
                const SizedBox(height: 18),
                AppButton.primary(
                  label: context.uiText('Crear pedido', 'Create order'),
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
    );
  }
}

class _DraftPurchaseLine {
  _DraftPurchaseLine({required this.productId});

  int productId;
  double qty = 1;
  double price = 0;
}

class _DraftPurchaseLineCard extends StatefulWidget {
  const _DraftPurchaseLineCard({
    required this.line,
    required this.products,
    required this.onRemove,
  });

  final _DraftPurchaseLine line;
  final List<Map<String, dynamic>> products;
  final VoidCallback onRemove;

  @override
  State<_DraftPurchaseLineCard> createState() => _DraftPurchaseLineCardState();
}

class _DraftPurchaseLineCardState extends State<_DraftPurchaseLineCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    final product = widget.products.firstWhere(
      (p) => OdooValues.intValue(p['id']) == widget.line.productId,
    );
    widget.line.price = widget.line.price <= 0
        ? (_num(product['standard_price']) > 0
              ? _num(product['standard_price'])
              : _num(product['list_price']))
        : widget.line.price;
    _qtyCtrl = TextEditingController(text: _formatQty(widget.line.qty));
    _priceCtrl = TextEditingController(text: _formatQty(widget.line.price));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: widget.line.productId,
            items: widget.products
                .map(
                  (product) => DropdownMenuItem<int>(
                    value: OdooValues.intValue(product['id']),
                    child: Text(
                      OdooValues.string(product['name'], fallback: 'Producto'),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                widget.line.productId = value;
                final product = widget.products.firstWhere(
                  (p) => OdooValues.intValue(p['id']) == value,
                );
                widget.line.price = _num(product['standard_price']) > 0
                    ? _num(product['standard_price'])
                    : _num(product['list_price']);
                _priceCtrl.text = _formatQty(widget.line.price);
              });
            },
            decoration: InputDecoration(
              labelText: context.uiText('Producto', 'Product'),
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _qtyCtrl,
                  labelText: context.uiText('Cantidad', 'Quantity'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.format_list_numbered_rounded,
                  onChanged: (value) => widget.line.qty = _parseDecimal(value),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AppInput(
                  controller: _priceCtrl,
                  labelText: context.uiText('Precio unitario', 'Unit price'),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  prefixIcon: Icons.euro_rounded,
                  onChanged: (value) =>
                      widget.line.price = _parseDecimal(value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: widget.onRemove,
              icon: Icon(Icons.delete_outline_rounded),
              label: Text(context.uiText('Quitar línea', 'Remove line')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceptionTab extends StatefulWidget {
  const _ReceptionTab();

  @override
  State<_ReceptionTab> createState() => _ReceptionTabState();
}

class _ReceptionTabState extends State<_ReceptionTab> {
  final OdooService _odoo = OdooService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  final AttachmentService _attachments = AttachmentService();
  final ImagePicker _imagePicker = ImagePicker();
  final NativeOcrService _ocr = NativeOcrService();
  final TextEditingController _orderCtrl = TextEditingController();
  bool _loading = false;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _lines = [];
  final Map<int, TextEditingController> _receivedCtrls = {};

  @override
  void dispose() {
    _orderCtrl.dispose();
    for (final ctrl in _receivedCtrls.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _pickInvoice() async {
    final noOrderDetected = context.uiText(
      'No detecté número de pedido en',
      'I could not detect an order number in',
    );
    final enterManually = context.uiText(
      'Escríbelo manualmente.',
      'Enter it manually.',
    );
    final file = await _attachments.pickAnyFile();
    if (file == null) return;
    String? detected;
    if (file.mimeType.toLowerCase().contains('pdf')) {
      detected = _extractPurchaseOrder(_extractPdfText(file.bytes));
    }
    detected ??= _extractPurchaseOrder(file.name);
    if (detected == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$noOrderDetected "${file.name}". $enterManually'),
        ),
      );
      return;
    }
    _orderCtrl.text = detected;
    await _loadOrder();
  }

  Future<void> _scanOrderWithCamera() async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'La lectura por cámara está disponible en iOS y Android.',
              'Camera scanning is available on iOS and Android.',
            ),
          ),
        ),
      );
      return;
    }

    final granted = await AppPermissionService.requestCamera();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'Necesitamos permiso de cámara para leer el pedido.',
              'Camera permission is required to scan the order.',
            ),
          ),
        ),
      );
      return;
    }

    final image = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 92,
      maxWidth: 1800,
      maxHeight: 1800,
    );
    if (image == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final recognizedText = await _ocr.recognizeTextFromImage(image.path);
      final detected = _extractPurchaseOrder(recognizedText);
      if (detected == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.uiText(
                'No detecté el código del pedido. Prueba con más luz o escríbelo manualmente.',
                'I could not detect the order code. Try more light or enter it manually.',
              ),
            ),
          ),
        );
        return;
      }
      _orderCtrl.text = detected;
      await _loadOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.uiText('No se pudo leer la imagen', 'Could not read the image')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOrder() async {
    final query = _orderCtrl.text.trim();
    if (query.isEmpty) return;
    final notFoundMessage =
        '${context.uiText('No he encontrado ningún pedido con', 'No order was found with')} "$query".';
    setState(() {
      _loading = true;
      _error = null;
      _order = null;
      _lines = [];
    });
    try {
      if (OdooService.sessionIsInternal(_odoo.sessionInfo) == true) {
        final payload = await _purchasesApi.detail(query: query);
        final rawOrder = OdooValues.map(payload['order']);
        _order = rawOrder;
        _lines =
            (rawOrder['lines'] is List ? rawOrder['lines'] as List : const [])
                .whereType<Map>()
                .map(OdooValues.map)
                .toList();
        _resetReceivedControllers();
      } else {
        final orders = await _odoo.searchRead(
          'purchase.order',
          domain: [
            ['name', 'ilike', query],
          ],
          fields: const [
            'name',
            'partner_id',
            'state',
            'date_order',
            'order_line',
          ],
          order: 'date_order desc',
          limit: 1,
        );
        if (orders.isEmpty) {
          _error = notFoundMessage;
        } else {
          _order = Map<String, dynamic>.from(orders.first as Map);
          final ids = OdooValues.ids(_order!['order_line']);
          if (ids.isNotEmpty) {
            final rows = await _odoo.searchRead(
              'purchase.order.line',
              domain: [
                ['id', 'in', ids],
              ],
              fields: const [
                'product_id',
                'name',
                'product_qty',
                'qty_received',
                'product_uom',
                'price_unit',
              ],
              order: 'id',
              limit: 200,
            );
            _lines = rows
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
            _resetReceivedControllers();
          }
        }
      }
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  void _resetReceivedControllers() {
    for (final ctrl in _receivedCtrls.values) {
      ctrl.dispose();
    }
    _receivedCtrls.clear();
    for (final line in _lines) {
      final id = (line['id'] as num?)?.toInt();
      if (id == null) continue;
      final pending = (_num(line['product_qty']) - _num(line['qty_received']))
          .clamp(0, double.infinity);
      _receivedCtrls[id] = TextEditingController(
        text: pending == 0 ? '0' : _formatQty(pending),
      );
    }
  }

  Future<void> _saveReception() async {
    final order = _order;
    if (order == null || _lines.isEmpty) return;
    final positiveQuantityMessage = context.uiText(
      'Indica una cantidad recibida mayor que cero.',
      'Enter a received quantity greater than zero.',
    );
    final exceedsPendingMessage = context.uiText(
      'Una cantidad supera la pendiente real del pedido. Revisa las líneas antes de guardar.',
      'A quantity exceeds the real pending amount for the order. Review the lines before saving.',
    );
    final savedMessage = context.uiText(
      'Recepción guardada y validada en Odoo.',
      'Receipt saved and validated in Odoo.',
    );
    final partialSavedPrefix = context.uiText(
      'Recepción parcial guardada. Queda pendiente',
      'Partial receipt saved. Still pending',
    );
    final noPickingsMessage = context.uiText(
      'No hay albaranes abiertos para este pedido o no tienes permisos de inventario.',
      'There are no open pickings for this order or you do not have inventory permissions.',
    );
    final noMovesMessage = context.uiText(
      'No hay movimientos pendientes en los albaranes visibles.',
      'There are no pending moves in the visible pickings.',
    );
    final couldNotSaveReceiptPrefix = context.uiText(
      'No se pudo guardar recepción',
      'Could not save receipt',
    );
    setState(() => _saving = true);
    try {
      final orderId = (order['id'] as num).toInt();
      if (OdooService.sessionIsInternal(_odoo.sessionInfo) == true) {
        final quantities = _lines
            .map((line) {
              final lineId = OdooValues.intValue(line['id']);
              final quantity = _parseDecimal(
                _receivedCtrls[lineId]?.text ?? '0',
              );
              final pending =
                  (_num(line['product_qty']) - _num(line['qty_received']))
                      .clamp(0, double.infinity);
              return lineId == null
                  ? null
                  : {
                      'line_id': lineId,
                      'quantity': quantity,
                      'pending': pending,
                    };
            })
            .whereType<Map<String, dynamic>>()
            .where((line) => _num(line['quantity']) > 0)
            .toList();
        if (quantities.isEmpty) {
          throw Exception(positiveQuantityMessage);
        }
        final invalid = quantities.where((line) {
          return _num(line['quantity']) > _num(line['pending']) + 0.000001;
        }).toList();
        if (invalid.isNotEmpty) {
          throw Exception(exceedsPendingMessage);
        }
        for (final line in quantities) {
          line.remove('pending');
        }
        final payload = await _purchasesApi.receive(orderId, quantities);
        final result = OdooValues.map(payload['result']);
        final remaining = result['remaining'] is List
            ? result['remaining'] as List
            : const <dynamic>[];
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              remaining.isEmpty
                  ? savedMessage
                  : '$partialSavedPrefix: ${remaining.join(', ')}.',
            ),
          ),
        );
        await _loadOrder();
        return;
      }
      final pickings = await _findOpenPurchasePickings(orderId);
      if (pickings.isEmpty) {
        throw Exception(noPickingsMessage);
      }
      final moveIds = <int>{};
      final pickingIds = <int>{};
      for (final rawPicking in pickings) {
        final picking = OdooValues.map(rawPicking);
        final pickingId = OdooValues.intValue(picking['id']);
        if (pickingId != null) pickingIds.add(pickingId);
        moveIds.addAll(OdooValues.ids(picking['move_ids_without_package']));
      }
      if (moveIds.isEmpty) {
        throw Exception(noMovesMessage);
      }
      final moves = await _odoo.searchRead(
        'stock.move',
        domain: [
          ['id', 'in', moveIds.toList()],
        ],
        fields: const ['purchase_line_id', 'state', 'picking_id'],
        limit: 200,
      );
      var appliedQuantity = false;
      for (final line in _lines) {
        final lineId = OdooValues.intValue(line['id']);
        if (lineId == null) continue;
        final qty = _parseDecimal(_receivedCtrls[lineId]?.text ?? '0');
        if (qty <= 0) continue;
        final candidates = moves
            .map(OdooValues.map)
            .where(
              (move) =>
                  OdooValues.many2oneId(move['purchase_line_id']) == lineId,
            )
            .toList();
        if (candidates.isEmpty) continue;
        final moveId = OdooValues.intValue(candidates.first['id']);
        if (moveId == null) continue;
        try {
          await _odoo.write('stock.move', moveId, {'quantity': qty});
        } catch (e) {
          await _odoo.write('stock.move', moveId, {'quantity_done': qty});
        }
        appliedQuantity = true;
      }
      if (!appliedQuantity) {
        throw Exception(positiveQuantityMessage);
      }
      for (final pickingId in pickingIds) {
        try {
          await _odoo.callRecordMethod('stock.picking', [
            pickingId,
          ], 'action_assign');
        } catch (e) {
          if (OdooService.isAccessError(e)) rethrow;
        }
        final result = await _odoo.callRecordMethod('stock.picking', [
          pickingId,
        ], 'button_validate');
        await _processPickingValidationResult(result);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(savedMessage)));
      await _loadOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$couldNotSaveReceiptPrefix: ${OdooService.prettyError(e)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<List<dynamic>> _findOpenPurchasePickings(int orderId) async {
    return _odoo.searchRead(
      'stock.picking',
      domain: [
        ['move_ids.purchase_line_id.order_id', '=', orderId],
        [
          'state',
          'not in',
          ['done', 'cancel'],
        ],
      ],
      fields: const ['name', 'move_ids_without_package'],
      limit: 20,
    );
  }

  Future<void> _processPickingValidationResult(dynamic result) async {
    final action = OdooValues.map(result);
    final model = OdooValues.string(action['res_model']);
    final id = OdooValues.intValue(action['res_id']);
    if (model.isEmpty || id == null) return;
    if (model == 'stock.immediate.transfer' ||
        model == 'stock.backorder.confirmation') {
      await _odoo.callRecordMethod(model, [id], 'process');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final order = _order;
    return RefreshIndicator(
      onRefresh: _loadOrder,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
        children: [
          AppSectionHeader(
            title: context.uiText('Recepción de pedidos', 'Order receipt'),
            subtitle: context.uiText(
              'Busca un pedido o adjunta la factura para detectar el número.',
              'Search for an order or attach the invoice to detect the number.',
            ),
          ),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _orderCtrl,
                  labelText: context.uiText('Número de pedido', 'Order number'),
                  hintText: 'PO00042 / P00042',
                  prefixIcon: Icons.receipt_long_rounded,
                  onSubmitted: (_) => _loadOrder(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _pickInvoice,
                icon: Icon(Icons.upload_file_rounded),
                tooltip: context.uiText('Cargar factura', 'Load invoice'),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _scanOrderWithCamera,
                icon: Icon(Icons.document_scanner_rounded),
                tooltip: context.uiText(
                  'Escanear con cámara',
                  'Scan with camera',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: context.uiText('Buscar pedido', 'Search order'),
            icon: Icons.search_rounded,
            loading: _loading,
            onPressed: _loading ? null : _loadOrder,
          ),
          const SizedBox(height: 18),
          if (_loading)
            SizedBox(
              height: 260,
              child: AppLoadingView(
                label: context.uiText('Cargando pedido...', 'Loading order...'),
              ),
            )
          else if (_error != null)
            AppEmptyState(
              title: context.uiText(
                'No se pudo cargar el pedido',
                'Could not load order',
              ),
              subtitle: _error!,
              icon: Icons.receipt_long_outlined,
            )
          else if (order == null)
            AppEmptyState(
              title: context.uiText('Busca un pedido', 'Search an order'),
              subtitle: context.uiText(
                'Introduce el número del pedido de compra o sube la factura para intentar detectarlo.',
                'Enter the purchase order number or upload the invoice to try to detect it.',
              ),
              icon: Icons.local_shipping_outlined,
            )
          else ...[
            _OrderHeader(order: order),
            const SizedBox(height: 14),
            AppSectionHeader(
              title: context.uiText('Líneas del pedido', 'Order lines'),
              subtitle: auth.canEditModule('purchases')
                  ? context.uiText(
                      'Indica cuántas unidades han llegado.',
                      'Enter how many units have arrived.',
                    )
                  : context.uiText(
                      'Consulta las cantidades pedidas y recibidas.',
                      'Review the ordered and received quantities.',
                    ),
            ),
            ..._lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ReceiptLineCard(
                  line: line,
                  controller:
                      _receivedCtrls[(line['id'] as num?)?.toInt()] ??
                      TextEditingController(),
                ),
              ),
            ),
            _PurchaseInvoices(order: order),
            const SizedBox(height: 8),
            if (auth.canEditModule('purchases'))
              AppButton.primary(
                label: context.uiText('Guardar recepción', 'Save receipt'),
                icon: Icons.task_alt_rounded,
                loading: _saving,
                onPressed: _saving ? null : _saveReception,
              ),
          ],
        ],
      ),
    );
  }
}

class _OrderHeader extends StatelessWidget {
  const _OrderHeader({required this.order, this.onTap});

  final Map<String, dynamic> order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final supplier = OdooValues.many2oneLabel(
      order['partner_id'],
      fallback: context.uiText('Proveedor', 'Supplier'),
    );
    final state = OdooValues.string(order['state']);
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.success.withValues(alpha: 0.12),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(
              Icons.shopping_cart_checkout_rounded,
              color: AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (order['name'] ?? context.uiText('Pedido', 'Order'))
                      .toString(),
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  supplier,
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: _purchaseStateLabel(context, state),
            color: AppTheme.primary,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMutedFor(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _PurchaseOrderDetailScreen extends StatefulWidget {
  const _PurchaseOrderDetailScreen({required this.orderId});

  final int orderId;

  @override
  State<_PurchaseOrderDetailScreen> createState() =>
      _PurchaseOrderDetailScreenState();
}

class _PurchaseOrderDetailScreenState
    extends State<_PurchaseOrderDetailScreen> {
  final OdooService _odoo = OdooService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _lines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final Map<String, dynamic> order;
      final List<dynamic> lines;
      if (OdooService.sessionIsInternal(_odoo.sessionInfo) == true) {
        final payload = await _purchasesApi.detail(orderId: widget.orderId);
        order = OdooValues.map(payload['order']);
        lines = order['lines'] is List ? order['lines'] as List : const [];
      } else {
        order = await _odoo.read(
          'purchase.order',
          widget.orderId,
          fields: const [
            'name',
            'partner_id',
            'state',
            'date_order',
            'amount_untaxed',
            'amount_total',
            'currency_id',
            'order_line',
          ],
        );
        final lineIds = OdooValues.ids(order['order_line']);
        lines = lineIds.isEmpty
            ? const <dynamic>[]
            : await _odoo.searchRead(
                'purchase.order.line',
                domain: [
                  ['id', 'in', lineIds],
                ],
                fields: const [
                  'product_id',
                  'name',
                  'product_qty',
                  'qty_received',
                  'product_uom',
                  'price_unit',
                  'date_planned',
                ],
                order: 'id',
                limit: 200,
              );
      }
      _order = order;
      _lines = lines.map((row) => OdooValues.map(row)).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _confirm() async {
    final auth = context.read<AuthProvider>();
    if (!auth.canEditModule('purchases')) return;
    setState(() => _saving = true);
    try {
      if (OdooService.sessionIsInternal(_odoo.sessionInfo) == true) {
        await _purchasesApi.confirm(widget.orderId);
      } else {
        await _odoo.callRecordMethod('purchase.order', [
          widget.orderId,
        ], 'button_confirm');
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.uiText(
                'Pedido confirmado en Odoo.',
                'Order confirmed in Odoo.',
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${context.uiText('No se pudo confirmar', 'Could not confirm')}: ${OdooService.prettyError(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final auth = context.watch<AuthProvider>();
    final state = OdooValues.string(order?['state']);
    final canConfirm =
        auth.canEditModule('purchases') &&
        const {'draft', 'sent', 'to approve'}.contains(state);
    return AppScaffold(
      title: OdooValues.string(
        order?['name'],
        fallback: context.uiText('Detalle del pedido', 'Order details'),
      ),
      actions: [
        IconButton(
          tooltip: context.uiText('Actualizar', 'Refresh'),
          onPressed: _load,
          icon: Icon(Icons.refresh_rounded),
        ),
      ],
      child: _loading
          ? AppLoadingView(
              label: context.uiText(
                'Cargando detalle...',
                'Loading details...',
              ),
            )
          : _error != null
          ? AppEmptyState(
              title: context.uiText(
                'No se pudo cargar el pedido',
                'Could not load order',
              ),
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
              action: AppButton.outline(
                label: context.uiText('Reintentar', 'Retry'),
                onPressed: _load,
              ),
            )
          : order == null
          ? AppEmptyState(
              title: context.uiText(
                'Pedido no disponible',
                'Order unavailable',
              ),
              subtitle: context.uiText(
                'Odoo no devolvió el registro solicitado.',
                'Odoo did not return the requested record.',
              ),
              icon: Icons.receipt_long_outlined,
            )
          : ListView(
              children: [
                _OrderHeader(order: order),
                const SizedBox(height: 14),
                Text(
                  '${context.l10n.date}: ${OdooValues.string(order['date_order'], fallback: context.uiText('Sin fecha', 'No date'))}',
                  style: TextStyle(color: AppTheme.textSecondaryFor(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  '${context.uiText('Total', 'Total')}: ${_formatQty(OdooValues.number(order['amount_total']))} ${OdooValues.many2oneLabel(order['currency_id'])}',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                AppSectionHeader(title: context.uiText('Líneas', 'Lines')),
                if (_lines.isEmpty)
                  AppEmptyState(
                    title: context.uiText('Sin líneas', 'No lines'),
                    subtitle: context.uiText(
                      'Este pedido no tiene líneas visibles para el usuario.',
                      'This order has no lines visible to the user.',
                    ),
                    icon: Icons.list_alt_outlined,
                  )
                else
                  ..._lines.map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ReceiptLineCard(
                        line: line,
                        controller: TextEditingController(text: '0'),
                        readOnly: true,
                      ),
                    ),
                  ),
                _PurchaseInvoices(order: order),
                if (canConfirm) ...[
                  const SizedBox(height: 8),
                  AppButton.primary(
                    label: context.uiText('Confirmar pedido', 'Confirm order'),
                    icon: Icons.check_circle_outline_rounded,
                    loading: _saving,
                    onPressed: _saving ? null : _confirm,
                  ),
                ],
              ],
            ),
    );
  }
}

class _ReceiptLineCard extends StatelessWidget {
  const _ReceiptLineCard({
    required this.line,
    required this.controller,
    this.readOnly = false,
  });

  final Map<String, dynamic> line;
  final TextEditingController controller;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final product = OdooValues.many2oneLabel(
      line['product_id'],
      fallback: OdooValues.string(line['name'], fallback: 'Producto'),
    );
    final ordered = OdooValues.number(line['product_qty']);
    final received = OdooValues.number(line['qty_received']);
    final unit = OdooValues.many2oneLabel(line['product_uom']);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(product, style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            '${context.uiText('Pedido', 'Ordered')}: ${_formatQty(ordered)} $unit · ${context.uiText('Recibido', 'Received')}: ${_formatQty(received)} $unit',
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          if (!readOnly &&
              context.watch<AuthProvider>().canEditModule('purchases'))
            AppInput(
              controller: controller,
              labelText: context.uiText(
                'Cantidad recibida ahora',
                'Quantity received now',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              prefixIcon: Icons.inventory_rounded,
            ),
        ],
      ),
    );
  }
}

class _PurchaseInvoices extends StatelessWidget {
  const _PurchaseInvoices({required this.order});

  final Map<String, dynamic> order;

  @override
  Widget build(BuildContext context) {
    final orderId = OdooValues.intValue(order['id']);
    final rawInvoices = order['invoices'];
    final invoices = rawInvoices is List
        ? rawInvoices.whereType<Map>().map(OdooValues.map).toList()
        : const <Map<String, dynamic>>[];
    if (orderId == null || invoices.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: context.uiText('Facturas', 'Invoices'),
            subtitle: context.uiText(
              'Consulta la factura de proveedor asociada al pedido.',
              'View the supplier invoice linked to this order.',
            ),
          ),
          ...invoices.map(
            (invoice) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PurchaseInvoiceCard(orderId: orderId, invoice: invoice),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseInvoiceCard extends StatefulWidget {
  const _PurchaseInvoiceCard({required this.orderId, required this.invoice});

  final int orderId;
  final Map<String, dynamic> invoice;

  @override
  State<_PurchaseInvoiceCard> createState() => _PurchaseInvoiceCardState();
}

class _PurchaseInvoiceCardState extends State<_PurchaseInvoiceCard> {
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  final AttachmentService _attachments = AttachmentService();
  bool _opening = false;

  Future<void> _open() async {
    final invoiceId = OdooValues.intValue(widget.invoice['id']);
    if (invoiceId == null || _opening) return;
    final emptyPdfMessage = context.uiText(
      'La factura no contiene un PDF.',
      'The invoice does not contain a PDF.',
    );
    final couldNotOpenPrefix = context.uiText(
      'No se pudo abrir la factura',
      'Could not open the invoice',
    );
    setState(() => _opening = true);
    try {
      final payload = await _purchasesApi.invoiceDocument(
        orderId: widget.orderId,
        invoiceId: invoiceId,
      );
      final encoded = OdooValues.string(payload['content']);
      if (encoded.isEmpty) {
        throw StateError(emptyPdfMessage);
      }
      final name = OdooValues.string(
        payload['name'],
        fallback: 'factura-$invoiceId.pdf',
      );
      final local = await _attachments.writeBytesToTemporary(
        name: name,
        bytes: base64Decode(encoded),
        folderName: 'facturas',
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            file: local,
            title: name,
            mimeType: OdooValues.string(
              payload['mimetype'],
              fallback: 'application/pdf',
            ),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$couldNotOpenPrefix: ${OdooService.prettyError(error)}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = OdooValues.string(
      widget.invoice['name'],
      fallback: OdooValues.string(
        widget.invoice['ref'],
        fallback: context.uiText('Factura', 'Invoice'),
      ),
    );
    final reference = OdooValues.string(widget.invoice['ref']);
    final date = OdooValues.string(widget.invoice['invoice_date']);
    final total = _formatQty(OdooValues.number(widget.invoice['amount_total']));
    final currency = OdooValues.many2oneLabel(widget.invoice['currency_id']);
    return AppCard(
      onTap: _opening ? null : _open,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.1),
              borderRadius: AppTheme.radiusSm,
            ),
            child: Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (reference.isNotEmpty && reference != title) reference,
                    if (date.isNotEmpty) date,
                    '$total $currency',
                  ].join(' · '),
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _opening
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  Icons.open_in_new_rounded,
                  color: AppTheme.textMutedFor(context),
                ),
        ],
      ),
    );
  }
}

double _num(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
}

double _parseDecimal(String value) =>
    double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;

String _formatQty(num value) {
  final doubleValue = value.toDouble();
  if (doubleValue == doubleValue.roundToDouble()) {
    return doubleValue.toInt().toString();
  }
  return doubleValue.toStringAsFixed(2);
}

String _purchaseStateLabel(BuildContext context, String state) {
  switch (state) {
    case 'draft':
      return context.uiText('Borrador', 'Draft');
    case 'sent':
      return context.uiText('Enviado', 'Sent');
    case 'to approve':
      return context.uiText('Pendiente de aprobación', 'Pending approval');
    case 'purchase':
      return context.uiText('Pedido confirmado', 'Order confirmed');
    case 'done':
      return context.uiText('Finalizado', 'Done');
    case 'cancel':
      return context.uiText('Cancelado', 'Cancelled');
    default:
      return state.isEmpty ? context.uiText('Pedido', 'Order') : state;
  }
}

String _formatOdooDateTime(DateTime value) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  final second = value.second.toString().padLeft(2, '0');
  return '$year-$month-$day $hour:$minute:$second';
}

String? _extractPurchaseOrder(String text) {
  final upper = text.toUpperCase();
  final cicCodePatterns = [
    // CIC purchase orders look like 26ALM-8. OCR often inserts spaces, so
    // normalize "26 ALM - 8" back to the Odoo order name "26ALM-8".
    RegExp(
      r'\b((?:20)?\d{2})\s*([A-ZÑ]{2,}[A-ZÑ0-9]{0,20})\s*-\s*([A-Z0-9]{1,12})\b',
    ),
    RegExp(
      r'\b((?:20)?\d{2})\s+([A-ZÑ]{2,}(?:\s+[A-ZÑ0-9]{1,}){0,4})\s*-\s*([A-Z0-9]{1,12})\b',
    ),
  ];
  for (final pattern in cicCodePatterns) {
    final match = pattern.firstMatch(upper);
    if (match == null) continue;
    final year = match.group(1) ?? '';
    final name = (match.group(2) ?? '').replaceAll(RegExp(r'\s+'), '');
    final order = match.group(3) ?? '';
    if (year.isNotEmpty && name.isNotEmpty && order.isNotEmpty) {
      return '$year$name-$order';
    }
  }

  final patterns = [
    RegExp(r'(PO\d{3,})'),
    RegExp(r'(P\d{4,})'),
    RegExp(r'(OC\d{3,})'),
    RegExp(r'(COMPRA[-_ ]?\d{3,})'),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(upper);
    if (match != null) return match.group(1)?.replaceAll(RegExp(r'[-_ ]'), '');
  }
  return null;
}

String _extractPdfText(List<int> bytes) {
  try {
    final document = PdfDocument(inputBytes: bytes);
    final text = PdfTextExtractor(document).extractText();
    document.dispose();
    return text;
  } catch (_) {
    return '';
  }
}
