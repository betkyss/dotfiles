# Мои dotfiles

Этот каталог содержит dotfiles для моей системы.

## Требования

Убедитесь, что в вашей системе установлено следующее:

### Git

```
pacman -S git
```

### Stow

```
pacman -S stow
```

## Установка 

Сначала проверьте репозиторий точечных файлов в каталоге $HOME, используя git.

```
$ git clone git@github.com:betkyss/dotfiles.git
$ cd dotfiles
```

Затем используйте GNU stow для создания символических ссылок

```
$ stow .
```

## Как обновлять
```
$ git add .
$ git commit -m ""
$ git push
```

![Превью](image.png)
