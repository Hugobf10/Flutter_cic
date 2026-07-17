import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../app/ui/app_components.dart';
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
      title: 'Compras',
      padding: EdgeInsets.zero,
      actions: const [_PurchasesRefreshButton()],
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Productos'),
                Tab(text: 'Pedidos'),
                Tab(text: 'Recepción'),
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
                  hintText: 'Buscar producto, referencia o código...',
                  onSubmitted: _load,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _scanSearch,
                icon: const Icon(Icons.qr_code_scanner_rounded),
                tooltip: 'Escanear código',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (auth.canEditModule('purchases')) ...[
            AppButton.primary(
              label: 'Nuevo producto',
              icon: Icons.add_rounded,
              onPressed: _openCreateProduct,
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 6),
          if (_loading)
            const SizedBox(
              height: 260,
              child: AppLoadingView(label: 'Cargando productos...'),
            )
          else if (_error != null)
            AppEmptyState(
              title: 'No se pudieron cargar productos',
              subtitle: _error!,
              icon: Icons.lock_outline_rounded,
              action: AppButton.outline(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: () => _load(_searchCtrl.text),
              ),
            )
          else if (_products.isEmpty)
            const AppEmptyState(
              title: 'Sin productos visibles',
              subtitle: 'Busca por nombre, referencia o código de barras.',
              icon: Icons.inventory_2_outlined,
            )
          else ...[
            AppSectionHeader(title: '${_products.length} productos'),
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
            child: const Icon(
              Icons.inventory_2_rounded,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product['name'] ?? 'Producto').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (ref.isNotEmpty) 'Ref. $ref',
                    if (barcode.isNotEmpty) 'EAN $barcode',
                    if (price != null) '${_num(price).toStringAsFixed(2)} €',
                  ].join(' · '),
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
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
                : AppTheme.textMuted,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(
              Icons.edit_outlined,
              size: 18,
              color: AppTheme.textMuted,
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
        const SnackBar(content: Text('El nombre del producto es obligatorio.')),
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
        if (id == null) throw StateError('Producto sin plantilla asociada.');
        await _odoo.write('product.template', id, payload);
      } else {
        await _odoo.create('product.template', payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Producto actualizado.' : 'Producto creado.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear: ${OdooService.prettyError(e)}'),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar producto' : 'Nuevo producto',
      actions: [
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const AppSectionHeader(
              title: 'Nuevo producto',
              subtitle: 'Crea la ficha básica de compra en Odoo.',
            ),
            AppInput(
              controller: _nameCtrl,
              labelText: 'Nombre',
              prefixIcon: Icons.inventory_2_outlined,
            ),
            const SizedBox(height: 10),
            AppInput(
              controller: _refCtrl,
              labelText: 'Referencia interna',
              prefixIcon: Icons.tag_rounded,
            ),
            const SizedBox(height: 10),
            AppInput(
              controller: _barcodeCtrl,
              labelText: 'Código de barras',
              prefixIcon: Icons.qr_code_2_rounded,
              suffixIcon: IconButton(
                onPressed: _scanBarcode,
                icon: const Icon(Icons.qr_code_scanner_rounded),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: AppInput(
                    controller: _costCtrl,
                    labelText: 'Coste',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.euro_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: AppInput(
                    controller: _priceCtrl,
                    labelText: 'Precio',
                    keyboardType: TextInputType.number,
                    prefixIcon: Icons.sell_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            AppButton.primary(
              label: _isEditing ? 'Guardar cambios' : 'Crear producto',
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
              label: 'Nuevo pedido de compra',
              icon: Icons.add_shopping_cart_rounded,
              onPressed: _openCreateOrder,
            ),
            const SizedBox(height: 18),
          ] else
            const SizedBox(height: 6),
          if (_loading)
            const SizedBox(
              height: 260,
              child: AppLoadingView(label: 'Cargando pedidos...'),
            )
          else if (_error != null)
            AppEmptyState(
              title: 'No se pudieron cargar pedidos',
              subtitle: _error!,
              icon: Icons.shopping_cart_outlined,
              action: AppButton.outline(
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: _load,
              ),
            )
          else if (_orders.isEmpty)
            const AppEmptyState(
              title: 'Sin pedidos visibles',
              subtitle:
                  'No hay pedidos de compra disponibles para este usuario.',
              icon: Icons.receipt_long_outlined,
            )
          else ...[
            AppSectionHeader(title: '${_orders.length} pedidos recientes'),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecciona un proveedor.')));
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Añade al menos una línea.')),
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
        invalidLines.add('producto no disponible');
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
        invalidLines.add('$productName sin unidad de compra');
        continue;
      }
      if (line.qty <= 0 || line.price < 0) {
        invalidLines.add('$productName con cantidad o precio inválido');
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
                ? 'No hay líneas válidas para crear el pedido.'
                : 'Revisa las líneas: ${invalidLines.join(', ')}.',
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
        const SnackBar(content: Text('Pedido de compra creado en borrador.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo crear el pedido: ${OdooService.prettyError(e)}',
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
      title: 'Nuevo pedido de compra',
      actions: [
        IconButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando opciones...')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudo preparar el pedido',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
            )
          : ListView(
              children: [
                const AppSectionHeader(
                  title: 'Pedido en borrador',
                  subtitle:
                      'Selecciona proveedor y añade las líneas de compra.',
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
                  decoration: const InputDecoration(
                    labelText: 'Proveedor',
                    prefixIcon: Icon(Icons.business_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                const AppSectionHeader(title: 'Líneas'),
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
                  label: 'Añadir línea',
                  icon: Icons.add_rounded,
                  onPressed: _addLine,
                ),
                const SizedBox(height: 18),
                AppButton.primary(
                  label: 'Crear pedido',
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
            decoration: const InputDecoration(
              labelText: 'Producto',
              prefixIcon: Icon(Icons.inventory_2_outlined),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _qtyCtrl,
                  labelText: 'Cantidad',
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
                  labelText: 'Precio unitario',
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
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Quitar línea'),
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
          content: Text(
            'No detecté número de pedido en "${file.name}". Escríbelo manualmente.',
          ),
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
        const SnackBar(
          content: Text(
            'La lectura por cámara está disponible en iOS y Android.',
          ),
        ),
      );
      return;
    }

    final granted = await AppPermissionService.requestCamera();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitamos permiso de cámara para leer el pedido.'),
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
          const SnackBar(
            content: Text(
              'No detecté el código del pedido. Prueba con más luz o escríbelo manualmente.',
            ),
          ),
        );
        return;
      }
      _orderCtrl.text = detected;
      await _loadOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo leer la imagen: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadOrder() async {
    final query = _orderCtrl.text.trim();
    if (query.isEmpty) return;
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
          _error = 'No he encontrado ningún pedido con "$query".';
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
              return lineId == null
                  ? null
                  : {'line_id': lineId, 'quantity': quantity};
            })
            .whereType<Map<String, dynamic>>()
            .where((line) => _num(line['quantity']) > 0)
            .toList();
        if (quantities.isEmpty) {
          throw Exception('Indica una cantidad recibida mayor que cero.');
        }
        await _purchasesApi.receive(orderId, quantities);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recepción guardada y validada en Odoo.'),
          ),
        );
        await _loadOrder();
        return;
      }
      final pickings = await _findOpenPurchasePickings(orderId);
      if (pickings.isEmpty) {
        throw Exception(
          'No hay albaranes abiertos para este pedido o no tienes permisos de inventario.',
        );
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
        throw Exception(
          'No hay movimientos pendientes en los albaranes visibles.',
        );
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
        throw Exception('Indica una cantidad recibida mayor que cero.');
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recepción guardada y validada en Odoo.')),
      );
      await _loadOrder();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo guardar recepción: ${OdooService.prettyError(e)}',
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
          const AppSectionHeader(
            title: 'Recepción de pedidos',
            subtitle:
                'Busca un pedido o adjunta la factura para detectar el número.',
          ),
          Row(
            children: [
              Expanded(
                child: AppInput(
                  controller: _orderCtrl,
                  labelText: 'Número de pedido',
                  hintText: 'PO00042 / P00042',
                  prefixIcon: Icons.receipt_long_rounded,
                  onSubmitted: (_) => _loadOrder(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _pickInvoice,
                icon: const Icon(Icons.upload_file_rounded),
                tooltip: 'Cargar factura',
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _scanOrderWithCamera,
                icon: const Icon(Icons.document_scanner_rounded),
                tooltip: 'Escanear con cámara',
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppButton.primary(
            label: 'Buscar pedido',
            icon: Icons.search_rounded,
            loading: _loading,
            onPressed: _loading ? null : _loadOrder,
          ),
          const SizedBox(height: 18),
          if (_loading)
            const SizedBox(
              height: 260,
              child: AppLoadingView(label: 'Cargando pedido...'),
            )
          else if (_error != null)
            AppEmptyState(
              title: 'No se pudo cargar el pedido',
              subtitle: _error!,
              icon: Icons.receipt_long_outlined,
            )
          else if (order == null)
            const AppEmptyState(
              title: 'Busca un pedido',
              subtitle:
                  'Introduce el número del pedido de compra o sube la factura para intentar detectarlo.',
              icon: Icons.local_shipping_outlined,
            )
          else ...[
            _OrderHeader(order: order),
            const SizedBox(height: 14),
            AppSectionHeader(
              title: 'Líneas del pedido',
              subtitle: auth.canEditModule('purchases')
                  ? 'Indica cuántas unidades han llegado.'
                  : 'Consulta las cantidades pedidas y recibidas.',
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
            const SizedBox(height: 8),
            if (auth.canEditModule('purchases'))
              AppButton.primary(
                label: 'Guardar recepción',
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
      fallback: 'Proveedor',
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
            child: const Icon(
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
                  (order['name'] ?? 'Pedido').toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  supplier,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AppStatusChip(
            label: _purchaseStateLabel(state),
            color: AppTheme.primary,
          ),
          if (onTap != null) ...[
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
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
          const SnackBar(content: Text('Pedido confirmado en Odoo.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo confirmar: ${OdooService.prettyError(e)}',
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
      title: OdooValues.string(order?['name'], fallback: 'Detalle del pedido'),
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: _loading
          ? const AppLoadingView(label: 'Cargando detalle...')
          : _error != null
          ? AppEmptyState(
              title: 'No se pudo cargar el pedido',
              subtitle: _error!,
              icon: Icons.error_outline_rounded,
              action: AppButton.outline(label: 'Reintentar', onPressed: _load),
            )
          : order == null
          ? const AppEmptyState(
              title: 'Pedido no disponible',
              subtitle: 'Odoo no devolvió el registro solicitado.',
              icon: Icons.receipt_long_outlined,
            )
          : ListView(
              children: [
                _OrderHeader(order: order),
                const SizedBox(height: 14),
                Text(
                  'Fecha: ${OdooValues.string(order['date_order'], fallback: 'Sin fecha')}',
                  style: const TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total: ${_formatQty(OdooValues.number(order['amount_total']))} ${OdooValues.many2oneLabel(order['currency_id'])}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 18),
                const AppSectionHeader(title: 'Líneas'),
                if (_lines.isEmpty)
                  const AppEmptyState(
                    title: 'Sin líneas',
                    subtitle:
                        'Este pedido no tiene líneas visibles para el usuario.',
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
                if (canConfirm) ...[
                  const SizedBox(height: 8),
                  AppButton.primary(
                    label: 'Confirmar pedido',
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
          Text(product, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Pedido: ${_formatQty(ordered)} $unit · Recibido: ${_formatQty(received)} $unit',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          if (!readOnly &&
              context.watch<AuthProvider>().canEditModule('purchases'))
            AppInput(
              controller: controller,
              labelText: 'Cantidad recibida ahora',
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

String _purchaseStateLabel(String state) {
  switch (state) {
    case 'draft':
      return 'Borrador';
    case 'sent':
      return 'Enviado';
    case 'to approve':
      return 'Pendiente de aprobación';
    case 'purchase':
      return 'Pedido confirmado';
    case 'done':
      return 'Finalizado';
    case 'cancel':
      return 'Cancelado';
    default:
      return state.isEmpty ? 'Pedido' : state;
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
