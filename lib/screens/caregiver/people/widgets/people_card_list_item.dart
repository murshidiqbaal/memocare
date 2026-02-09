import 'package:flutter/material.dart';

import '../../../../data/models/person.dart';

class PeopleCardListItem extends StatelessWidget {
  final Person person;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PeopleCardListItem(
      {super.key,
      required this.person,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundImage:
              person.photoUrl != null ? NetworkImage(person.photoUrl!) : null,
          child: person.photoUrl == null
              ? Text(person.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 24))
              : null,
        ),
        title: Text(
          person.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(person.relationship,
                style: TextStyle(color: Colors.teal.shade700)),
            if (person.voiceAudioUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  children: [
                    Icon(Icons.mic, size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 4),
                    Text('Voice Note',
                        style: TextStyle(
                            color: Colors.orange.shade700, fontSize: 12)),
                  ],
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
                icon: const Icon(Icons.edit, color: Colors.blueGrey),
                onPressed: onEdit),
            IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}
