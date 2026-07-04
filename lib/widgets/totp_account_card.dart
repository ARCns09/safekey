import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:otp/otp.dart';
import '../database/database.dart';
import '../core/providers.dart';

class TotpAccountCard extends ConsumerStatefulWidget {
  final Account account;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const TotpAccountCard({
    super.key, 
    required this.account,
    this.isSelected = false,
    this.onLongPress,
    this.onTap,
  });

  @override
  ConsumerState<TotpAccountCard> createState() => _TotpAccountCardState();
}

class _TotpAccountCardState extends ConsumerState<TotpAccountCard> {
  late Timer _timer;
  String _code = '';
  double _progress = 0.0;
  bool _isCopied = false;
  bool _isRevealed = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _updateCode();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      _updateCode();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCode() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final periodMs = widget.account.period * 1000;
    
    // Calculate remaining time
    final remainder = now % periodMs;
    final remainingTimeMs = periodMs - remainder;
    final progress = remainingTimeMs / periodMs;

    Algorithm alg;
    switch (widget.account.algorithm) {
      case 'SHA256':
        alg = Algorithm.SHA256;
        break;
      case 'SHA512':
        alg = Algorithm.SHA512;
        break;
      default:
        alg = Algorithm.SHA1;
    }

    try {
      final code = OTP.generateTOTPCodeString(
        widget.account.secret,
        now,
        length: widget.account.digits,
        interval: widget.account.period,
        algorithm: alg,
        isGoogle: true,
      );

      if (mounted) {
        setState(() {
          _code = code;
          _progress = progress;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _code = 'ERROR';
          _progress = 0;
        });
      }
    }
  }

  void _copyToClipboard() async {
    if (_code == 'ERROR') return;
    
    await Clipboard.setData(ClipboardData(text: _code));
    setState(() {
      _isCopied = true;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.account.accountName} code copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isCopied = false;
        });
      }
    });
  }

  void _handleTap() {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    
    final hideCodes = ref.read(hideCodesProvider);
    if (hideCodes && !_isRevealed) {
      setState(() {
        _isRevealed = true;
      });
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _isRevealed = false;
          });
        }
      });
      return;
    }
    
    _copyToClipboard();
  }

  @override
  Widget build(BuildContext context) {
    final hideCodes = ref.watch(hideCodesProvider);
    
    // Format code with a space in the middle for readability if it's 6 or 8 digits
    String displayCode = _code;
    
    if (hideCodes && !_isRevealed) {
      displayCode = '*** ***';
    } else {
      if (_code.length == 6) {
        displayCode = '${_code.substring(0, 3)} ${_code.substring(3)}';
      } else if (_code.length == 8) {
        displayCode = '${_code.substring(0, 4)} ${_code.substring(4)}';
      }
    }

    return AnimatedScale(
      scale: _isPressed ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      child: Card(
        color: widget.isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).cardColor,
        elevation: widget.isSelected ? 4 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: InkWell(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: _handleTap,
          onLongPress: widget.onLongPress,
          borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              if (widget.isSelected)
                 Padding(
                   padding: const EdgeInsets.only(right: 16.0),
                   child: Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
                 ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.account.issuer,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (widget.account.isPinned)
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Icon(Icons.push_pin, size: 16, color: Theme.of(context).colorScheme.primary),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.account.accountName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: Text(
                        _isCopied ? 'Copied!' : displayCode,
                        key: ValueKey<String>(_isCopied ? 'copied' : displayCode),
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: _isCopied ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: _isCopied ? 1.0 : 3.0,
                          fontSize: _isCopied ? 20.0 : null,
                          fontFamily: _isCopied ? null : 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 48,
                height: 48,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: _progress, end: _progress),
                  duration: const Duration(milliseconds: 100),
                  builder: (context, value, child) {
                    final color = value < 0.2 ? Colors.red : Theme.of(context).colorScheme.primary;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 4,
                          backgroundColor: Colors.grey.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                        if (value < 0.2)
                          const Icon(Icons.warning_amber_rounded, size: 20, color: Colors.red)
                        else
                          Icon(Icons.lock_clock, size: 20, color: color.withValues(alpha: 0.5)),
                      ],
                    );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }

}
