import 'package:flutter/material.dart';

import '../models/installment.dart';

class InstallmentTile extends StatelessWidget {

  final Installment installment;

  const InstallmentTile({
    super.key,
    required this.installment,
  });

  @override
  Widget build(BuildContext context) {

    return Card(

      elevation: 2,

      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.circular(14),
      ),

      child: ListTile(

        leading: CircleAvatar(
          backgroundColor:
          installment.isPaid
              ? Colors.green.shade50
              : Colors.orange.shade50,

          child: Icon(
            installment.isPaid
                ? Icons.check
                : Icons.schedule,
            color:
            installment.isPaid
                ? Colors.green
                : Colors.orange,
          ),
        ),

        title: Text(
          installment.monthName,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          "${installment.paidAmount.toInt()} FCFA / ${installment.amount.toInt()} FCFA",
        ),

        trailing: Container(
          padding:
          const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 6,
          ),

          decoration: BoxDecoration(
            color:
            installment.isPaid
                ? Colors.green
                .withOpacity(.1)
                : Colors.red
                .withOpacity(.1),

            borderRadius:
            BorderRadius.circular(20),
          ),

          child: Text(
            installment.isPaid
                ? "Payé"
                : "Impayé",
            style: TextStyle(
              color:
              installment.isPaid
                  ? Colors.green
                  : Colors.red,
              fontWeight:
              FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}