
#Использовать logos
#Использовать json
#Использовать fs

Перем Лог;

#Область ОбщийФункционал

Функция ПолучитьЛог() Экспорт
	Возврат Логирование.ПолучитьЛог("oscript.web.hub-frontend");
КонецФункции

Функция ПрочитатьJSON(Знач Путь, Знач КакСтруктуру = Ложь) Экспорт
	Файл = Новый ЧтениеТекста(Путь);
	Текст = Файл.Прочитать();
	Файл.Закрыть();
	Парсер = Новый ПарсерJSON;
	Данные = Парсер.ПрочитатьJSON(Текст,,,КакСтруктуру);
	Возврат Данные;
КонецФункции

Функция ЗначениеПеременнойСреды(ИмяПараметра) Экспорт
	
	ЗначениеПеременной = ПолучитьПеременнуюСреды(ИмяПараметра);
	Возврат Строка(ЗначениеПеременной); // неопределено в строку
	
КонецФункции

Функция ДвоичныеДанныеИзHTTPЗапроса(ЗапросHTTP) Экспорт
	
	Поток = ЗапросHTTP.ПолучитьТелоКакПоток();
	ЧтениеДанных = Новый ЧтениеДанных(Поток);
	Возврат ЧтениеДанных.Прочитать().ПолучитьДвоичныеДанные();
	
КонецФункции

Функция ВычислитьКодОшибки(ИнформацияОбОшибке) Экспорт
	
	ПараметрыОшибки = ИнформацияОбОшибке.Параметры;
	Если ПараметрыОшибки = Неопределено Тогда
		ПараметрыОшибки = 500;
	КонецЕсли;
	Возврат ПараметрыОшибки;
	
КонецФункции

Функция КаталогПубликации() Экспорт
	
	КаталогПубликации = ЗначениеПеременнойСреды("PATH_TO_OSCRIPT_HUB");
	Если Не ЗначениеЗаполнено(КаталогПубликации) Тогда
		КаталогПубликации = "/var/www/hub.oscript.io";
	КонецЕсли;
	
	Возврат КаталогПубликации;
	
КонецФункции

#КонецОбласти

#Область РаботаСПакетом
 
Процедура ЗафиксироватьПакет(Каталог, ДвоичныеДанные, ИмяФайла, ОписаниеПакета, РелизныйКанал) Экспорт
	
	ПутьККаталогуПакета = ОбъединитьПути(Каталог, ОписаниеПакета.Идентификатор);
	ФС.ОбеспечитьКаталог(ПутьККаталогуПакета);
	ДвоичныеДанные.Записать(ОбъединитьПути(ПутьККаталогуПакета, ИмяФайла));
	ДвоичныеДанные.Записать(ОбъединитьПути(ПутьККаталогуПакета, ОписаниеПакета.Идентификатор + ".ospx"));

	ЗафиксироватьПакетВБД(ОписаниеПакета, ПутьККаталогуПакета, ИмяФайла, РелизныйКанал);
	СформироватьList(Каталог);
	
КонецПроцедуры

Процедура ЗафиксироватьПакетВБД(ОписаниеПакета, ПутьККаталогуПакета, ИмяФайла, РелизныйКанал)

	Идентификатор = ОписаниеПакета.Идентификатор;
	ТекущаяДата = ТекущаяДата();

	// запись в БД
	ИмяКанала = ?(РелизныйКанал, "stable", "develop");
	Отбор = Новый Соответствие();
	Отбор.Вставить("Имя", ИмяКанала);
	Канал = МенеджерБазыДанных.МенеджерСущностей.ПолучитьОдно(Тип("Канал"), Отбор);
	Если Канал = Неопределено Тогда
		Канал = Новый Канал();
		Канал.Имя = ИмяКанала;
		Канал.Каталог = ?(РелизныйКанал, "download", "dev-channel");
		Канал.Сохранить();
	КонецЕсли;
	
	// пишем в пакет
	Пакет = МенеджерБазыДанных.МенеджерСущностей.ПолучитьОдно(Тип("Пакет"), Идентификатор);
	Если Пакет = Неопределено Тогда
		Пакет = Новый Пакет;
		Пакет.Код = Идентификатор; 
		Пакет.Наименование = Пакет.Код;
	КонецЕсли;

	// Автор ?
	Если Не ЗначениеЗаполнено(Пакет.Автор) Тогда
		МетаданныеПакета = ПереченьПакетов.МетаданныеПакета(ОбъединитьПути(ПутьККаталогуПакета, ИмяФайла));
		АвторИмя = "";
		МетаданныеПакета.Свойство("Автор", АвторИмя); 
		Если ЗначениеЗаполнено(АвторИмя) Тогда
			Пакет.Автор = МиграцияДанных.ПолучитьСоздатьАвтора(АвторИмя);
		КонецЕсли;
	КонецЕсли;

	Если Не ЗначениеЗаполнено(Пакет.СсылкаНаПроект) Тогда
		Пакет.СсылкаНаПроект = СсылкаНаПроектПоПакету(Пакет);
	КонецЕсли;

	Пакет.Сохранить();
	
	// пишем в пакет канала
	Отбор = Новый Соответствие();
	Отбор.Вставить("Канал", Канал.Код);
	Отбор.Вставить("Пакет", Пакет.Код);
	ПакетКанала = МенеджерБазыДанных.МенеджерСущностей.ПолучитьОдно(Тип("ПакетКанала"), Отбор);
	Если ПакетКанала = Неопределено Тогда
		ПакетКанала = Новый ПакетКанала();
		ПакетКанала.Пакет = Пакет.Код;
		ПакетКанала.Путь = ОбъединитьПути(Канал.Каталог, ПакетКанала.Пакет);
		ПакетКанала.Канал = Канал;
		ПакетКанала.ДатаСоздания = ТекущаяДата;
	КонецЕсли;

	// АктуальнаяВерсияДО = ПакетКанала.АктуальнаяВерсия;
	// АктуальнаяВерсия = МиграцияДанных.АктуальнаяВерсияПакетаИзКанала(Пакет.Код, ПакетКанала);
	// ПакетКанала.АктуальнаяВерсия = ?(АктуальнаяВерсия = Неопределено, АктуальнаяВерсияДО, АктуальнаяВерсия);

	ПакетКанала.ДатаОбновления = ТекущаяДата;
	ПакетКанала.Сохранить();
	
	// пишем в версии пакетов
	Зависимости = МиграцияДанных.ПрочитатьЗависимостиПакета(ОбъединитьПути(ПутьККаталогуПакета, Идентификатор + ".ospx"));
	
	Отбор = Новый Соответствие();
	Отбор.Вставить("Номер", ОписаниеПакета.Версия);
	Отбор.Вставить("ПакетКанала", ПакетКанала.Код);
	ВерсияПакета = МенеджерБазыДанных.МенеджерСущностей.ПолучитьОдно(Тип("ВерсияПакета"), Отбор);
	Если ВерсияПакета = Неопределено Тогда
		
		ВерсияПакета = Новый ВерсияПакета();
		ВерсияПакета.Номер = ОписаниеПакета.Версия;
		ВерсияПакета.Пакет = Пакет.Код;
		ВерсияПакета.ПакетКанала = ПакетКанала.Код;
		ВерсияПакета.Путь = ОбъединитьПути(Канал.Каталог, ПакетКанала.Пакет, ИмяФайла);
		ВерсияПакета.Канал = Канал.Код;
		ВерсияПакета.ДатаСоздания = ТекущаяДата;
		
	КонецЕсли;
	
	ВерсияПакета.ДатаОбновления = ТекущаяДата;
	// чистить старые зависимости?
	ВерсияПакета.Зависимости = МиграцияДанных.ЗависимостиВерсииПакета(Зависимости);
	ВерсияПакета.Сохранить();

	АктуальнаяВерсияДО = ПакетКанала.АктуальнаяВерсия;
	АктуальнаяВерсия = МиграцияДанных.АктуальнаяВерсияПакетаИзКанала(Пакет.Код, ПакетКанала);
	ПакетКанала.АктуальнаяВерсия = ?(АктуальнаяВерсия = Неопределено, АктуальнаяВерсияДО, АктуальнаяВерсия);
	ПакетКанала.Сохранить();

КонецПроцедуры

Процедура СформироватьList(КаталогПубликации)
	
	ПутьКСпискуПакетов = ОбъединитьПути(КаталогПубликации, "list.txt");
	НайденныеФайлы = НайтиФайлы(КаталогПубликации, ПолучитьМаскуВсеФайлы(), Ложь);
	ЗаписьТекста = Новый ЗаписьТекста(ПутьКСпискуПакетов, КодировкаТекста.UTF8NoBom);
	
	Для Каждого НайденныйФайл Из НайденныеФайлы Цикл
		
		Если НайденныйФайл.ЭтоФайл() Тогда
			Продолжить;
		КонецЕсли;
		
		ЗаписьТекста.ЗаписатьСтроку(НайденныйФайл.Имя);
		
	КонецЦикла;
	
	ЗаписьТекста.Закрыть();
	
КонецПроцедуры

Процедура ПроверитьКорректностьФайла(ИмяФайла) Экспорт
	Если НЕ СтрЗаканчиваетсяНа(ИмяФайла, ".ospx") Тогда
		ВызватьИсключение
		Новый ИнформацияОбОшибке("Недопустимое расширение файла пакета. Допускаются только файлы ospx.", 401);
	КонецЕсли;
КонецПроцедуры

Функция ОписаниеПакета(ИмяФайла) Экспорт
	
	Описание = Новый Структура;
	Описание.Вставить("Идентификатор", ИмяПакетаИзИмениФайла(ИмяФайла));
	Описание.Вставить("Версия", ВерсияПакетаИзИмениФайла(ИмяФайла));
	
	Возврат Описание;
	
КонецФункции

Функция ИмяПакетаИзИмениФайла(ИмяФайла)
	
	ИмяПакетаМассив = СтрРазделить(ИмяФайла, "-");
	ИмяПакета = "";
	Для сч = 0 По ИмяПакетаМассив.ВГраница() - 1 Цикл
		ИмяПакета = ИмяПакета + ИмяПакетаМассив[сч] + "-";
	КонецЦикла;
	ИмяПакета = Лев(ИмяПакета, СтрДлина(ИмяПакета) - 1);
	
	Возврат ИмяПакета;
	
КонецФункции

Функция ВерсияПакетаИзИмениФайла(ИмяФайла)
	
	ИмяПакетаМассив = СтрРазделить(ИмяФайла, "-");
	Версия = ИмяПакетаМассив[ИмяПакетаМассив.ВГраница()];
	Версия = СтрЗаменить(Версия, ".ospx", "");
	
	Возврат Версия;
	
КонецФункции

Функция СсылкаНаПроектПоПакету(Пакет)

	Результат = "";
	
	Сервер = "https://github.com";
	Соединение = Новый HTTPСоединение(Сервер);
	Адрес = СтрШаблон("oscript-library/%1", Пакет.Код);

	Запрос = Новый HTTPЗапрос(Адрес);
	Ответ = Соединение.Получить(Запрос);
	Если Ответ.КодСостояния <> 200 Тогда
		Адрес = СтрШаблон("oscript-library/%1", Пакет.Наименование); // так ли? или из nameRemap?
		Запрос = Новый HTTPЗапрос(Адрес);
		Ответ = Соединение.Получить(Запрос);
	КонецЕсли;

	Если Ответ.КодСостояния = 200 Тогда
		Результат = Сервер + "/" + 	Адрес;
	КонецЕсли;

	Возврат Результат;

КонецФункции

#КонецОбласти

#Область github

Функция ИмяПользователяПоТокенуАвторизации(ТокенАвторизации) Экспорт
	
	Соединение = СоединениеGithub();
	РесурсРепозиторий = "/user";
	ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, ЗаголовкиЗапросаGithub(ТокенАвторизации));
	
	ОтветРепозиторий = Соединение.Получить(ЗапросРепозиторий);
	ТелоОтвета = ОтветРепозиторий.ПолучитьТелоКакСтроку();
	
	Если ОтветРепозиторий.КодСостояния <> 200 Тогда
		ВызватьИсключение Новый ИнформацияОбОшибке(ТелоОтвета, 401);
	КонецЕсли;
	
	ПарсерJSON = Новый ПарсерJSON();
	ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(ТелоОтвета);
	АвторизованныйПользователь = ДанныеОтвета["login"];
	
	Возврат АвторизованныйПользователь;
	
КонецФункции

Процедура ПроверитьПравоОтправкиВРепозиторий(ИмяПользователя, ИмяРепозитория) Экспорт
	
	ТокенАвторизации = ОбщегоНазначения.ЗначениеПеременнойСреды("GITHUB_SUPER_TOKEN");
	
	Соединение = СоединениеGithub();
	РесурсРепозиторий = СтрШаблон("/repos/oscript-library/%1/collaborators", ИмяРепозитория);
	ЗапросРепозиторий = Новый HTTPЗапрос(РесурсРепозиторий, ЗаголовкиЗапросаGithub(ТокенАвторизации));
	
	ОтветРепозиторий = Соединение.Получить(ЗапросРепозиторий);
	ТелоОтвета = ОтветРепозиторий.ПолучитьТелоКакСтроку();
	
	Если ОтветРепозиторий.КодСостояния <> 200 Тогда
		ВызватьИсключение Новый ИнформацияОбОшибке(ТелоОтвета, 500);
	КонецЕсли;
	
	ПарсерJSON = Новый ПарсерJSON();
	ДанныеОтвета = ПарсерJSON.ПрочитатьJSON(ТелоОтвета);
	
	ПользовательИмеетПраваОтправки = Ложь;
	
	Для Каждого ДанныеКоллаборатора Из ДанныеОтвета Цикл
		Если ДанныеКоллаборатора["login"] = ИмяПользователя И ДанныеКоллаборатора["permissions"]["push"] Тогда
			ПользовательИмеетПраваОтправки = Истина;
		КонецЕсли;
	КонецЦикла;
	
	Если НЕ ПользовательИмеетПраваОтправки Тогда
		ВызватьИсключение Новый ИнформацияОбОшибке("Пользователь не имеет права отправки в репозиторий пакета", 401);
	КонецЕсли;
	
КонецПроцедуры

Функция СоединениеGithub()
	
	Сервер = "https://api.github.com";
	Возврат Новый HTTPСоединение(Сервер);
	
КонецФункции

Функция ЗаголовкиЗапросаGithub(ТокенАвторизации)
	
	ЗаголовкиЗапроса = Новый Соответствие();
	ЗаголовкиЗапроса.Вставить("Accept", "application/vnd.github.v3+json");
	ЗаголовкиЗапроса.Вставить("User-Agent", "oscript-library-autobuilder");
	ЗаголовкиЗапроса.Вставить("Authorization", СтрШаблон("token %1", ТокенАвторизации));
	Возврат ЗаголовкиЗапроса;
	
КонецФункции

#КонецОбласти

Лог = ПолучитьЛог();