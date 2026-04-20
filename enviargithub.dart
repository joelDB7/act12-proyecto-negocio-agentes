import 'dart:io';

void main() async {
  print('===================================================');
  print('    Agente Interactivo para Enviar a GitHub');
  print('===================================================\n');

  // 1. Preguntar por el link del nuevo repositorio como entrada de dato
  stdout.write('1. Introduce el link del nuevo repositorio de GitHub (ej. https://github.com/usuario/repo.git): ');
  String? repoLink = stdin.readLineSync()?.trim();
  if (repoLink == null || repoLink.isEmpty) {
    print('Error: El link del repositorio no puede estar vacío. Operación cancelada.');
    return;
  }

  // 2. Preguntar por el commit como entrada de dato
  stdout.write('2. Introduce el mensaje del commit: ');
  String? commitMessage = stdin.readLineSync()?.trim();
  if (commitMessage == null || commitMessage.isEmpty) {
    commitMessage = 'Primer commit / Actualización de proyecto';
    print('   -> Mensaje vacío. Se usará por defecto: "$commitMessage"');
  }

  // 3. Establecer la rama main por default o pedir nombre de la rama
  stdout.write('3. Introduce el nombre de la rama (presiona Enter para usar "main" por defecto): ');
  String? branchName = stdin.readLineSync()?.trim();
  if (branchName == null || branchName.isEmpty) {
    branchName = 'main';
  }

  print('\n---------------------------------------------------');
  print('Resumen de la operación a realizar:');
  print('- URL del Repositorio: $repoLink');
  print('- Mensaje de Commit:   $commitMessage');
  print('- Nombre de la Rama:   $branchName');
  print('---------------------------------------------------\n');

  stdout.write('¿Deseas continuar para subir tu código? (s/n): ');
  String? confirm = stdin.readLineSync()?.trim().toLowerCase();
  if (confirm != 's' && confirm != 'si' && confirm != 'y' && confirm != 'yes') {
    print('Operación cancelada por el usuario.');
    return;
  }

  print('\nIniciando proceso...\n');

  // Función de apoyo para ejecutar los comandos de sistema
  Future<bool> runCommand(String executable, List<String> arguments) async {
    print('> $executable ${arguments.join(' ')}');
    var result = await Process.run(executable, arguments);
    if (result.stdout.toString().trim().isNotEmpty) print('  ${result.stdout.toString().trim()}');
    if (result.stderr.toString().trim().isNotEmpty) print('  [Aviso/Error]: ${result.stderr.toString().trim()}');
    return result.exitCode == 0;
  }

  // a. Revisar si es un repositorio git
  var gitStatus = await Process.run('git', ['status']);
  if (gitStatus.exitCode != 0) {
    print('Inicializando repositorio git local...');
    await runCommand('git', ['init']);
  }

  // b. Agregar todos los archivos
  await runCommand('git', ['add', '.']);

  // c. Guardar los cambios con el commit
  await runCommand('git', ['commit', '-m', commitMessage]);

  // d. Establecer la rama
  await runCommand('git', ['branch', '-M', branchName]);

  // e. Manejar la conexión remota (origin)
  var remoteResult = await Process.run('git', ['remote']);
  if (remoteResult.stdout.toString().contains('origin')) {
    await runCommand('git', ['remote', 'set-url', 'origin', repoLink]);
  } else {
    await runCommand('git', ['remote', 'add', 'origin', repoLink]);
  }

  // f. Enviar los cambios
  print('\nEnviando repositorio a GitHub, por favor espera...');
  var pushSuccess = await runCommand('git', ['push', '-u', 'origin', branchName]);

  if (pushSuccess) {
    print('\n===================================================');
    print(' ✅ ¡Repositorio enviado a GitHub exitosamente! 🚀 ');
    print('===================================================');
  } else {
    print('\n❌ Ocurrió un problema al subir a GitHub.');
    print('Por favor, revisa tus credenciales, conexión de internet o si el link del repositorio es correcto e intenta de nuevo.');
  }
}
