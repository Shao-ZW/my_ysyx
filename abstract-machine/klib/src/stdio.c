#include <am.h>
#include <klib.h>
#include <klib-macros.h>
#include <stdarg.h>
#include <limits.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

int print_num(int base, unsigned int num, bool sign) {
  static const char digits[] = "0123456789abcdef";
  char buf[15];
  int idx = 0;

  if(sign) {
    if((int)num < 0) {
      num = (unsigned int)-num;
      putch('-');
    }
  }

  do {
    buf[idx++] = digits[num % base];
    num /= base;
  } while(num);

  for(int i = idx - 1; i >= 0; --i)
    putch(buf[i]);

  return idx;
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);

  unsigned int num;
  char *s;
  int cnt = 0;


  for( ; *fmt; fmt++) {
    if(*fmt != '%') {
      putch(*fmt);
      cnt++;
      continue;
    }

    fmt++;
    switch(*fmt) {
      case 'c':
        num = va_arg(ap, int);
        cnt++;
        putch((char)num);
        break;

      case 'd':
      case 'i':
        num = va_arg(ap, unsigned int);
        cnt += print_num(10, num, 1);
        break;

      case 'u':
        num = va_arg(ap, unsigned int);
        cnt += print_num(10, num, 0);
        break;

      case 'o':
        num = va_arg(ap, unsigned int);
        cnt += print_num(8, num, 0);
        break;

      case 'x':
      case 'X':
        num = va_arg(ap, unsigned int);
        cnt += print_num(16, num, 0);
        break;
      
      case 'p':
      case 'P':
        num = (unsigned int)va_arg(ap, void *);
        putch('0'); putch('x');
        cnt += print_num(16, num, 0);
        break;
      
      case 's':
        s = va_arg(ap, char*);
        if(!s) {
          s = "(NULL)";
        }

        for (const char *p = s; *p; p++) {
          cnt++;
          putch(*p);
        }
        break;

      case '%':
        cnt++;
        putch('%');
        break;
      
      default:
        return -1;
    }
  }

  return cnt;
}

static char* sprint_num(char *str, char *end, int base, unsigned int num, bool sign) {
  static const char digits[] = "0123456789abcdef";
  char buf[15];
  int idx = 0;

  if(sign) {
    if((int)num < 0) {
      num = (unsigned int)-num;
      if(str < end) {
        *str = '-';
      }
      str++;
    }
  }

  do {
    buf[idx++] = digits[num % base];
    num /= base;
  } while(num);

  while(idx) {
    if(str < end) {
      *str = buf[idx - 1];
    }
    str++;
    idx--;
  }

  return str;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return vsnprintf(out, (size_t)-1, fmt, ap);
}

int sprintf(char *out, const char *fmt, ...) {
  int rval;
  va_list args;
  va_start(args, fmt);
  rval = vsprintf(out, fmt, args);
  va_end(args);
  return rval;
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  int rval;
  va_list args;
  va_start(args, fmt);
  rval = vsnprintf(out, n, fmt, args);
  va_end(args);
  return rval;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  char *str, *end;
  unsigned int num;
  char *s;

  str = out;
  end = out + n;

  if (end < str) {
    end  = ((char *) - 1);
    n = end - str;
  }
  
  for( ; *fmt; fmt++) {
    if(*fmt != '%') {
      if(str < end) {
        *str = *fmt;
      }
      str++;
      continue;
    }

    fmt++;
    switch(*fmt) {
      case 'd':
      case 'i':
        num = va_arg(ap, unsigned int);
        str = sprint_num(str, end, 10, num, 1);
        break;

      case 'u':
        num = va_arg(ap, unsigned int);
        str = sprint_num(str, end, 10, num, 0);
        break;
      
      case 'o':
        num = va_arg(ap, unsigned int);
        str = sprint_num(str, end, 8, num, 0);
        break;

      case 'x':
      case 'X':
        num = va_arg(ap, unsigned int);
        str = sprint_num(str, end, 16, num, 0);
        break;

      case 'p':
      case 'P':
        *(str++) = '0'; *(str++) = 'x';
        num = (unsigned int)va_arg(ap, void *);
        str = sprint_num(str, end, 16, num, 0);
        break;

      case 's':
        s = va_arg(ap, char*);
        if(!s) {
          s = "(NULL)";
        }
      
        while(*s) {
          if(str < end) {
            *str = *s;
          }
          s++;
          str++;
        }
        break;

      case '%':
        if(str < end) {
          *str = '%';
        }
        str++;
        break;
      
      default:
        return -1;
    }
  }

  if (n > 0) {
      if (str < end) {
        *str = '\0';
      }
      else {
        end[-1] = '\0';
      }
  }

  return str - out;
}

#endif
