// Firestore security rules tests. Run via:
//   firebase emulators:exec --only firestore --project demo-gigflow "npm --prefix security test"
import { readFileSync } from 'node:fs';
import { after, before, beforeEach, describe, test } from 'node:test';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  Timestamp,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  setDoc,
  updateDoc,
} from 'firebase/firestore';

let env;
const now = Timestamp.fromDate(new Date('2026-11-22T10:00:00Z'));
const later = Timestamp.fromDate(new Date('2026-11-22T12:00:00Z'));

const validTask = (over = {}) => ({
  title: 'Deliver order #4821',
  description: 'Fragile',
  dueDate: later,
  priority: 'high',
  isCompleted: false,
  category: 'delivery',
  createdAt: now,
  updatedAt: now,
  ...over,
});

const alice = () => env.authenticatedContext('alice').firestore();
const bob = () => env.authenticatedContext('bob').firestore();
const anon = () => env.unauthenticatedContext().firestore();
const aliceTask = (db, id = 't1') => doc(db, 'users/alice/tasks', id);

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-gigflow',
    firestore: { rules: readFileSync(new URL('../firestore.rules', import.meta.url), 'utf8') },
  });
});
after(async () => env?.cleanup());
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alice/tasks/seed'), validTask());
  });
});

describe('authentication', () => {
  test('signed-out users cannot read or write anything', async () => {
    await assertFails(getDoc(aliceTask(anon(), 'seed')));
    await assertFails(setDoc(aliceTask(anon(), 'x'), validTask()));
    await assertFails(getDocs(collection(anon(), 'users/alice/tasks')));
  });
});

describe('authorization (tenant isolation)', () => {
  test('owner can create, read, list, update and delete own tasks', async () => {
    const db = alice();
    await assertSucceeds(setDoc(aliceTask(db, 'new'), validTask()));
    await assertSucceeds(getDoc(aliceTask(db, 'new')));
    await assertSucceeds(getDocs(collection(db, 'users/alice/tasks')));
    await assertSucceeds(updateDoc(aliceTask(db, 'new'), { isCompleted: true, updatedAt: later }));
    await assertSucceeds(deleteDoc(aliceTask(db, 'new')));
  });

  test("another user cannot read, list, write or delete someone else's tasks", async () => {
    const db = bob();
    await assertFails(getDoc(aliceTask(db, 'seed')));
    await assertFails(getDocs(collection(db, 'users/alice/tasks')));
    await assertFails(setDoc(aliceTask(db, 'evil'), validTask()));
    await assertFails(updateDoc(aliceTask(db, 'seed'), { isCompleted: true }));
    await assertFails(deleteDoc(aliceTask(db, 'seed')));
  });

  test('paths outside users/{uid}/tasks are denied by default', async () => {
    await assertFails(setDoc(doc(alice(), 'users/alice'), { role: 'admin' }));
    await assertFails(setDoc(doc(alice(), 'admin/config'), { open: true }));
    await assertFails(getDoc(doc(alice(), 'users/alice/secrets/x')));
  });
});

describe('schema validation', () => {
  const bad = {
    'missing title': (() => { const t = validTask(); delete t.title; return t; })(),
    'empty title': validTask({ title: '' }),
    'title too long': validTask({ title: 'x'.repeat(201) }),
    'description too long': validTask({ description: 'x'.repeat(1001) }),
    'title wrong type': validTask({ title: 42 }),
    'unknown priority': validTask({ priority: 'urgent' }),
    'unknown category': validTask({ category: 'hacking' }),
    'isCompleted not bool': validTask({ isCompleted: 'yes' }),
    'dueDate not timestamp': validTask({ dueDate: '2026-11-22' }),
    'extra field (mass assignment)': validTask({ isAdmin: true }),
  };
  for (const [name, data] of Object.entries(bad)) {
    test(`rejects ${name}`, async () => {
      await assertFails(setDoc(aliceTask(alice(), 'bad'), data));
    });
  }

  test('accepts legacy v1.0 documents without a category', async () => {
    const t = validTask(); delete t.category;
    await assertSucceeds(setDoc(aliceTask(alice(), 'legacy'), t));
  });

  test('rejects oversized document ids', async () => {
    await assertFails(setDoc(aliceTask(alice(), 'x'.repeat(129)), validTask()));
  });
});

describe('integrity', () => {
  test('owner can toggle and edit an existing task (createdAt kept)', async () => {
    await assertSucceeds(
      updateDoc(aliceTask(alice(), 'seed'), { isCompleted: true, updatedAt: later }),
    );
    await assertSucceeds(
      setDoc(aliceTask(alice(), 'seed'), validTask({ title: 'Edited', updatedAt: later })),
    );
  });
  test('createdAt cannot be rewritten on update', async () => {
    await assertFails(updateDoc(aliceTask(alice(), 'seed'), { createdAt: later }));
  });
  test('update cannot inject extra fields', async () => {
    await assertFails(updateDoc(aliceTask(alice(), 'seed'), { owner: 'bob' }));
  });
  test('update cannot break the schema', async () => {
    await assertFails(updateDoc(aliceTask(alice(), 'seed'), { priority: 'critical' }));
  });
});
