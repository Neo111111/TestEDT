// Операция начала обмена
// проверяет, что нужный узел добавлен в план и правильно инициализирован
//
// Параметры:
//  КодУзла	– идентификатор данного узла, используется как код узла плана обмена
//  НаименованиеМобильногоКомпьютера - читаемое представление данного узла, не обязательно, изменяемое, используется как наименование узла плана обмена
//  НомерОтправленного - номер последнего отправленного пакета, предназначен для восстановления обмена, если узел был удален
//  НомерПринятого - номер последнего принятого пакета, предназначен для восстановления обмена, если узел был удален
//
// Возвращаемое значение:
//  нет
//
Функция НачатьОбмен(КодУзла, НаименованиеМобильногоКомпьютера, НомерОтправленного, НомерПринятого, Версия)
    
    Если Число(Версия) <> 5 Тогда
        
        ВызватьИсключение(НСтр("ru='Требуется обновление мобильного приложения!'"));
        
    КонецЕсли;
        
    Если НЕ ПравоДоступа("Чтение", Метаданные.ПланыОбмена.Мобильные) Тогда
        
        ВызватьИсключение(НСтр("ru='У пользователя ""'") + Пользователи.ТекущийПользователь() + НСтр("ru='"" нет прав на синхронизацию данных с приложением 1С:Заказы'"));
        
    КонецЕсли;
    
	УстановитьПривилегированныйРежим(Истина);
    
	УзелОбмена = ПланыОбмена.Мобильные.ЭтотУзел().ПолучитьОбъект();
    Если Не ЗначениеЗаполнено(УзелОбмена.Код) Тогда
        
    	УзелОбмена.Код="001";
    	УзелОбмена.Наименование="Центральный";
    	УзелОбмена.Записать();
        
    КонецЕсли;
	
	Пользователь = Пользователи.ТекущийПользователь();
    УзелОбмена = ПланыОбмена.Мобильные.НайтиПоКоду(КодУзла); 
    Если УзелОбмена.Пустая() Тогда
		
        НовыйУзел = ПланыОбмена.Мобильные.СоздатьУзел();
		
		НачатьТранзакцию();
		
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки = Блокировка.Добавить("Константа.КодНовогоУзлаПланаОбмена");
		ЭлементБлокировки.Режим = РежимБлокировкиДанных.Исключительный;
		Блокировка.Заблокировать();

		КодНовогоУзла = Константы.КодНовогоУзлаПланаОбмена.Получить();
		Если КодНовогоУзла = 0 Тогда 
			КодНовогоУзла = 2;
		КонецЕсли;	
		Константы.КодНовогоУзлаПланаОбмена.Установить(КодНовогоУзла + 1);
		
		ЗафиксироватьТранзакцию();
		
		Если СтрДлина(КодНовогоУзла) < 3 Тогда
			НовыйУзел.Код = Формат(КодНовогоУзла, "ЧЦ=3; ЧВН=");
		Иначе
			НовыйУзел.Код = КодНовогоУзла;
		КонецЕсли;
        НовыйУзел.Наименование = НаименованиеМобильногоКомпьютера;
        НовыйУзел.НомерОтправленного = НомерОтправленного;
        НовыйУзел.НомерПринятого = НомерПринятого;
        НовыйУзел.Пользователь = Пользователь;
        НовыйУзел.Записать();
        ОбменМобильныеПереопределяемый.ЗарегистрироватьИзмененияДанных(НовыйУзел.Ссылка);
        УзелОбмена = НовыйУзел.Ссылка;
        
    Иначе
        
        Если УзелОбмена.ПометкаУдаления ИЛИ            
             УзелОбмена.Наименование <> НаименованиеМобильногоКомпьютера Тогда
             
            Узел = УзелОбмена.ПолучитьОбъект();
            Узел.ПометкаУдаления = Ложь;
            Узел.Наименование = НаименованиеМобильногоКомпьютера;
            Узел.Записать();
            
        КонецЕсли;
        
        Если УзелОбмена.НомерОтправленного <> НомерОтправленного ИЛИ
             УзелОбмена.НомерПринятого <> НомерПринятого Тогда
             
            Узел = УзелОбмена.ПолучитьОбъект();
            Узел.НомерОтправленного = НомерОтправленного;
            Узел.НомерПринятого = НомерПринятого;
            Узел.Записать();
            ОбменМобильныеПереопределяемый.ЗарегистрироватьИзмененияДанных(УзелОбмена);
            
		КонецЕсли;
		
        Если УзелОбмена.Пользователь <> Пользователь Тогда
            Узел = УзелОбмена.ПолучитьОбъект();
            Узел.Пользователь = Пользователь;
            Узел.Записать();
        КонецЕсли;
        
	КонецЕсли;
    Возврат УзелОбмена.Код;
КонецФункции

// Операция получения данных
// получает пакет изменений предназначенных для данного узла
//
// Параметры:
//  КодУзла	– код узла, с которым идет обмен
//
// Возвращаемое значение:
//  ХранилищеЗначения, в которое помещен пакет обмена
//
Функция ПолучитьДанные(КодУзла)
    
    УзелОбмена = ПланыОбмена.Мобильные.НайтиПоКоду(КодУзла); 
    
    Если УзелОбмена.Пустая() Тогда
        ВызватьИсключение(НСтр("ru='Неизвестное устройство - '") + КодУзла);
    КонецЕсли;
    ОбменМобильныеПереопределяемый.СформироватьЗаказанныеОтчеты(УзелОбмена);
    Возврат ОбменМобильныеОбщее.СформироватьПакетОбмена(УзелОбмена);
    
КонецФункции

// Операция записи данных
// записывает пакет изменений принятых от данного узла
//
// Параметры:
//  КодУзла	– код узла, с которым идет обмен
//  ДанныеМобильногоПриложения - ХранилищеЗначения, в которое помещен пакет обмена
//
// Возвращаемое значение:
//  нет
//
Функция ЗаписатьДанные(КодУзла, ДанныеМобильногоПриложения)

    УзелОбмена = ПланыОбмена.Мобильные.НайтиПоКоду(КодУзла); 
    
    Если УзелОбмена.Пустая() Тогда
        ВызватьИсключение(НСтр("ru='Неизвестное устройство - '") + КодУзла);
	КонецЕсли;
    ОбменМобильныеОбщее.ПринятьПакетОбмена(УзелОбмена, ДанныеМобильногоПриложения);
    
КонецФункции

// Операция удаленного получения отчета
//
// Параметры:
//  Настройки	– настройки отчета, структура сериализованная в XDTO 
//
// Возвращаемое значение:
//  ТабличныйДокумент - сформированный отчет, сериализованный в XDTO 
//
Функция ПолучитьОтчет(Настройки, СтрокаИнформацииРасшифровки)
    
    ИнформацияРасшифровки = Неопределено;
    ТабличныйДокумент = ОбменМобильныеПереопределяемый.СформироватьОтчет(Настройки, ИнформацияРасшифровки);
    СтрокаИнформацииРасшифровки = СериализаторXDTO.ЗаписатьXDTO(ИнформацияРасшифровки);
    Возврат СериализаторXDTO.ЗаписатьXDTO(ТабличныйДокумент);
    
КонецФункции

Функция НовыйИдентификаторПодписчикаУведомлений(КодУзла, ИдентификаторXDTO)
	
    Идентификатор = СериализаторXDTO.ПрочитатьXDTO(ИдентификаторXDTO);
	УзелОбмена = ПланыОбмена.Мобильные.НайтиПоКоду(КодУзла); 
	
	Если УзелОбмена.Пустая() Тогда
	    ВызватьИсключение(НСтр("ru='Неизвестное устройство - '") + КодУзла);
	КонецЕсли;
	
	Узел = УзелОбмена.ПолучитьОбъект();
	Узел.ИдентификаторПодписчикаДоставляемыхУведомлений = Новый ХранилищеЗначения(Идентификатор);
	Узел.Записать();
	
КонецФункции
