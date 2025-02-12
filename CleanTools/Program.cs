using CleanTools;

NugetCacheCleaner.Clean();
await PowershellCommandsCleaner.Clean();
FoldersCleaner.Clean();
Console.ReadLine();