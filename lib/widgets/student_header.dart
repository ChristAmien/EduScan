import 'package:flutter/material.dart';

import '../models/etudiant.dart';

class StudentHeader extends StatelessWidget {

  final Student student;
  final bool upToDate;

  const StudentHeader({
    super.key,
    required this.student,
    required this.upToDate,
  });

  @override
  Widget build(BuildContext context) {

    return Container(

      width: double.infinity,

      padding: const EdgeInsets.all(24),

      decoration: const BoxDecoration(
        color: Color(0xFF0055E5),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),

      child: Column(

        children: [

          CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white,
            child: Text(
              student.initials,
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0055E5),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            student.fullName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "${student.filiereName ?? '-'} • ${student.level ?? '-'}",
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color:
              upToDate
                  ? Colors.green
                  : Colors.red,
              borderRadius:
              BorderRadius.circular(30),
            ),
            child: Text(
              upToDate
                  ? "À JOUR"
                  : "IMPAYÉ",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.15),
              borderRadius:
              BorderRadius.circular(15),
            ),
            child: Column(
              children: [

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "Matricule",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    Text(
                      student.studentId,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [

                    const Text(
                      "Téléphone",
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),

                    Text(
                      student.phone ?? "-",
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}