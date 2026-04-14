// Экран отзыва и чаевых - показывается клиенту после оплаты

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../order_selling_sdk.dart';

class ReviewScreen extends StatefulWidget {
  final String orderId;
  final VoidCallback onComplete;

  const ReviewScreen({
    super.key,
    required this.orderId,
    required this.onComplete,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _stars = 0;
  final _tipsController = TextEditingController();
  double _selectedQuickTip = 0;
  bool _isSending = false;

  static const _quickTips = [50.0, 100.0, 200.0, 500.0];

  @override
  void dispose() {
    _tipsController.dispose();
    super.dispose();
  }

  double get _tipsAmount {
    if (_selectedQuickTip > 0) return _selectedQuickTip;
    final text = _tipsController.text;
    if (text.isEmpty) return 0;
    return double.tryParse(text) ?? 0;
  }

  Future<void> _submit() async {
    final requestedTips = _tipsAmount;
    SdkLogger.info('Отзыв: $_stars звёзд, запрошенные чаевые: $requestedTips сом');

    // Если чаевые не указаны - просто отправляем отзыв
    if (requestedTips <= 0) {
      setState(() => _isSending = true);
      await _sendReviewCallback(paidTips: 0, tipsPaid: false);
      if (!mounted) return;
      setState(() => _isSending = false);
      widget.onComplete();
      return;
    }

    // Подтверждение реального списания (по ТЗ п.12.3: чаевые -
    // это реальный платёж через GoodooPay, подтверждено клиентом)
    final confirmed = await _confirmTipsPayment(requestedTips);
    if (!confirmed) return;

    if (!mounted) return;
    setState(() => _isSending = true);

    // Реальный платёж чаевых через GoodooPay
    final tipsResult = await _processTips(requestedTips);

    if (!mounted) return;

    // Если оплата не прошла - предлагаем отправить отзыв без чаевых
    if (!tipsResult.paid) {
      setState(() => _isSending = false);
      if (tipsResult.errorShown) return; // пользователь уже увидел ошибку и закрыл

      final sendWithoutTips = await _askSendWithoutTips(tipsResult.message);
      if (sendWithoutTips != true) return;

      setState(() => _isSending = true);
      await _sendReviewCallback(paidTips: 0, tipsPaid: false);
      setState(() => _isSending = false);
      widget.onComplete();
      return;
    }

    // Оплата чаевых успешна - отправляем финальный callback
    await _sendReviewCallback(
      paidTips: requestedTips,
      tipsPaid: true,
    );

    setState(() => _isSending = false);
    widget.onComplete();
  }

  // Отправка отзыва в систему учёта (формат 1С: поле "otzyv" — текст)
  Future<void> _sendReviewCallback({
    required double paidTips,
    required bool tipsPaid,
  }) async {
    // Формируем текстовый отзыв для поля otzyv
    final parts = <String>[];
    if (_stars > 0) parts.add('$_stars из 5');
    if (tipsPaid && paidTips > 0) {
      parts.add('чаевые ${paidTips.toInt()} оплачены');
    }
    final reviewText = parts.isNotEmpty ? parts.join(', ') : null;

    final provider = context.read<OrdersProvider>();
    await CallbackQueue.enqueue(CallbackData(
      orderNumber: widget.orderId,
      statusPay: 'оплачено',
      statusDoc: 'доставлен',
      review: reviewText,
    ));

    if (provider.api != null) {
      await CallbackQueue.flush(provider.api!);
    }
  }

  // Диалог подтверждения реального списания чаевых
  Future<bool> _confirmTipsPayment(double amount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        title: const Text('Оплатить чаевые?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.qr_code_2, size: 64, color: AppTheme.primaryColor),
            const SizedBox(height: 12),
            Text(
              '${amount.toInt()}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Это реальный платёж через банковское приложение.\n'
              'Сумма будет списана с вашей карты.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Оплатить'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // Диалог "оплата не прошла, отправить отзыв без чаевых?"
  Future<bool?> _askSendWithoutTips(String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        title: const Text('Чаевые не оплачены'),
        content: Text('$message\n\nОтправить отзыв без чаевых?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Назад'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Отправить'),
          ),
        ],
      ),
    );
  }

  Future<_TipsPaymentOutcome> _processTips(double amount) async {
    final paymentProvider = OrderSellingSDK.paymentProvider;
    if (paymentProvider == null || !(await paymentProvider.isAvailable())) {
      SdkLogger.warning('Чаевые: платёжная система недоступна');
      return _TipsPaymentOutcome.failed(
        'Платёжная система недоступна.',
      );
    }

    SdkLogger.info('Чаевые: запуск GoodooPay на $amount сом');

    if (!mounted) return _TipsPaymentOutcome.failed('Экран закрыт');

    final result = await paymentProvider.payByQR(
      amount: amount,
      description: 'Чаевые',
      context: context,
    );

    if (result.isSuccess) {
      SdkLogger.info('Чаевые: оплата успешна');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Чаевые ${amount.toInt()} успешно оплачены. Спасибо!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
      return _TipsPaymentOutcome.success();
    } else if (result.isCancelled) {
      SdkLogger.info('Чаевые: оплата отменена клиентом');
      return _TipsPaymentOutcome.failed('Оплата отменена.');
    } else {
      SdkLogger.error('Чаевые: ошибка оплаты - ${result.error}');
      return _TipsPaymentOutcome.failed(
        result.error ?? 'Ошибка оплаты чаевых.',
      );
    }
  }

  void _skip() {
    SdkLogger.info('Отзыв: пропущен');
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.check_circle_outline, size: 72, color: AppTheme.successColor),
              const SizedBox(height: 16),
              const Text(
                'Оплата прошла успешно!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 32),
              const Text('Оцените доставку', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 12),
              _buildStars(),
              const SizedBox(height: 32),
              const Text('Чаевые (по желанию)', style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 12),
              _buildQuickTips(),
              const SizedBox(height: 12),
              _buildTipsInput(),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _stars > 0 && !_isSending ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSending
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Готово', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isSending ? null : _skip,
                child: const Text('Пропустить', style: TextStyle(color: Colors.grey)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStars() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNumber = index + 1;
        return GestureDetector(
          onTap: () => setState(() => _stars = starNumber),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(
              starNumber <= _stars ? Icons.star : Icons.star_border,
              size: 44,
              color: starNumber <= _stars ? Colors.amber : Colors.grey[300],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildQuickTips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: _quickTips.map((amount) {
        final isSelected = _selectedQuickTip == amount;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: ChoiceChip(
            label: Text('${amount.toInt()}'),
            selected: isSelected,
            selectedColor: AppTheme.primaryColor.withValues(alpha: 0.2),
            onSelected: (selected) {
              setState(() {
                _selectedQuickTip = selected ? amount : 0;
                _tipsController.text = selected ? amount.toInt().toString() : '';
              });
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTipsInput() {
    return SizedBox(
      width: 200,
      child: TextField(
        controller: _tipsController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: 'Другая сумма',
          suffixText: '',
          border: OutlineInputBorder(borderRadius: AppTheme.borderRadiusMedium),
        ),
        onChanged: (_) => setState(() => _selectedQuickTip = 0),
      ),
    );
  }
}

// Результат попытки оплаты чаевых
class _TipsPaymentOutcome {
  final bool paid;
  final String message;
  final bool errorShown;

  _TipsPaymentOutcome._({
    required this.paid,
    required this.message,
    required this.errorShown,
  });

  factory _TipsPaymentOutcome.success() =>
      _TipsPaymentOutcome._(paid: true, message: '', errorShown: false);

  factory _TipsPaymentOutcome.failed(String message) =>
      _TipsPaymentOutcome._(paid: false, message: message, errorShown: false);
}
