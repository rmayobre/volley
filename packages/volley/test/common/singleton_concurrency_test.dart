import 'dart:async';
import 'dart:math';

import 'package:test/test.dart';
import 'package:volley/volley.dart';

final class Job implements Message {
  final int id;
  final int delayMs;
  const Job(this.id, [this.delayMs = 0]);
}

final class Done implements Message {
  final int id;

  /// The highest number of reduce() calls that were running at once so far.
  final int peak;
  const Done(this.id, [this.peak = 0]);
}

/// Shared body: tracks how many reduce() calls overlap.
mixin _Tracking {
  int _running = 0;
  int _peak = 0;

  Future<Done> track(Job job) async {
    _running++;
    _peak = max(_peak, _running);
    await Future.delayed(Duration(milliseconds: job.delayMs));
    _running--;
    return Done(job.id, _peak);
  }
}

final class SerialWorker extends SerializedSingleton<Done, Job> with _Tracking {
  @override
  Future<Done> reduce(Job event) => track(event);
}

final class OtherSerialWorker extends SerializedSingleton<Done, Job>
    with _Tracking {
  @override
  Future<Done> reduce(Job event) => track(event);
}

final class ConcurrentWorker extends ConcurrentSingleton<Done, Job>
    with _Tracking {
  @override
  Future<Done> reduce(Job event) => track(event);
}

// --- check / await / act: unsafe unless reduce() calls are serialized ---

final class Withdraw implements Message {
  final int amount;
  const Withdraw(this.amount);
}

final class Balance implements Message {
  final int value;
  const Balance(this.value);
}

final class Account extends SerializedSingleton<Balance, Withdraw> {
  int _balance = 100;

  @override
  Future<Balance> reduce(Withdraw cmd) async {
    if (_balance >= cmd.amount) {
      await Future.delayed(const Duration(milliseconds: 20));
      _balance -= cmd.amount; // acts on the check above
    }
    return Balance(_balance);
  }
}

// --- a concurrent singleton that is called back from inside its own reduce ---

final class Nester extends ConcurrentSingleton<Done, Job> {
  @override
  Future<Done> reduce(Job job) async {
    if (job.id != 0) return Done(job.id);
    final inner = await coroutine(_callBack).result;
    return Done(100 + inner);
  }
}

/// Runs as a coroutine: sends a second message to [Nester] and awaits it.
Future<int> _callBack() async {
  final channel = await Singleton.instance<Done, Job, Nester>(Nester.new);
  final reply = channel.messages.where((d) => d.id == 1).first;
  channel.send(const Job(1));
  return (await reply).id;
}

void main() {
  setUpAll(() => Bootstrapper.initialize());

  const wait = Duration(seconds: 5);

  group('SerializedSingleton', () {
    test('runs one reduce at a time and replies in send order', () async {
      final ch = await Singleton.instance<Done, Job, SerialWorker>(
        SerialWorker.new,
      );
      final replies = ch.messages.take(3).toList();

      // The first message is the slowest: a concurrent singleton would answer
      // it last.
      ch.send(const Job(0, 90));
      ch.send(const Job(1, 40));
      ch.send(const Job(2, 0));

      final done = await replies.timeout(wait);
      expect(done.map((d) => d.id), [0, 1, 2]);
      expect(done.last.peak, 1, reason: 'reduce calls must never overlap');
    });

    test('check/await/act sequences are safe', () async {
      final ch = await Singleton.instance<Balance, Withdraw, Account>(
        Account.new,
      );
      final replies = ch.messages.take(2).map((b) => b.value).toList();

      ch.send(const Withdraw(80));
      ch.send(const Withdraw(80));

      // Concurrently, both would pass the check and leave -60.
      expect(await replies.timeout(wait), [20, 20]);
    });

    test('different singletons do not wait for each other', () async {
      final slow = await Singleton.instance<Done, Job, SerialWorker>(
        SerialWorker.new,
      );
      final other = await Singleton.instance<Done, Job, OtherSerialWorker>(
        OtherSerialWorker.new,
      );

      final order = <String>[];
      slow.messages.listen((_) => order.add('slow'));
      other.messages.listen((_) => order.add('other'));

      slow.send(const Job(10, 150));
      other.send(const Job(11, 0));

      await Future.delayed(const Duration(milliseconds: 400));
      expect(order, ['other', 'slow']);
    });
  });

  group('ConcurrentSingleton', () {
    test('overlaps reduce calls, so replies follow completion order', () async {
      final ch = await Singleton.instance<Done, Job, ConcurrentWorker>(
        ConcurrentWorker.new,
      );
      final replies = ch.messages.take(2).toList();

      ch.send(const Job(0, 150));
      ch.send(const Job(1, 0));

      final done = await replies.timeout(wait);
      expect(done.map((d) => d.id), [1, 0], reason: 'fast job finishes first');
      expect(done.last.peak, 2, reason: 'both reduce calls were running');
    });

    test('can be called back from inside its own reduce', () async {
      final ch = await Singleton.instance<Done, Job, Nester>(Nester.new);
      final reply = ch.messages.where((d) => d.id >= 100).first;
      ch.send(const Job(0));

      // A serialized singleton would wait on itself here forever.
      expect((await reply.timeout(wait)).id, 101);
    });
  });
}
