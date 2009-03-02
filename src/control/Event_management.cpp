#include "Event_management.h"

bool E_management::tried_to_talk = false;

E_management::E_management()
{
    NScene = NULL;
    running = NULL;
    use_keyboard = NULL;
    myaudio = NULL;
    myteam = NULL;
    Events = NULL;//agregar apuntador a vector de eventos
    Charas_nps = NULL;
    Actor = NULL;
    data = NULL;
    chip = NULL;
}

void E_management::page_refresh()
{
    unsigned int i;
    int current_page,old_page;
    std::string system_string;
    std::string * old_string;
    std::string * new_string;
    SDL_Surface *temp2;

    for (i = 0; i < Events->size(); i++)
    {
        current_page=Active_page(&Events->at(i));
        old_page=Ev_state->at(i).Active_page;
        if(old_page!=current_page)// la pagina activa actual y si esta es diferente a la pagina activa anterior

        if(current_page!=-1)
        {
            if(old_page!=-1)
            old_string = &Events->at(i).vcPage[old_page].CharsetName;
            new_string = &Events->at(i).vcPage[current_page].CharsetName;
            if((old_page==-1)|| (!(new_string->compare(*old_string))))
            {
            system_string.clear();
            system_string.append("CharSet/");
            system_string.append(Events->at(i).vcPage[current_page].CharsetName);
            system_string.append(".png");
            if (!system_string.compare("CharSet/.png"))
            {
                temp2 = CreateSurface(24, 32);
                chip->RenderTile(temp2, 4, 16, Events->at(i).vcPage[current_page].CharsetID + 0x2710, 0);
                Charas_nps->at(i).dispose();
                Charas_nps->at(i).set_surface(temp2);
            }
            else
            {
                Charas_nps->at(i).dispose();
                Charas_nps->at(i).setimg((char *) system_string.c_str(), Events->at(i).vcPage[current_page].CharsetID);
            }
            }
                Charas_nps->at(i).dir = Events->at(i).vcPage[current_page].Facing_direction;
                Charas_nps->at(i).frame = Events->at(i).vcPage[current_page].Animation_frame+1;
                Charas_nps->at(i).move_dir= Mov_management->get_dir(Events->at(i).vcPage[current_page].Movement_type);
                Charas_nps->at(i).move_frec=Events->at(i).vcPage[current_page].Movement_frequency;
                Charas_nps->at(i).anim_frec=Events->at(i).vcPage[current_page].Movement_speed;
                Charas_nps->at(i).layer=Events->at(i).vcPage[current_page].Event_height;
                if(old_page==-1)//restart the position
                Charas_nps->at(i).setposXY(Events->at(i).X_position, Events->at(i).Y_position);
        }
        else
        {
            //current_page =-1
                temp2 = CreateSurface(24, 32);
                Charas_nps->at(i).dispose();
                Charas_nps->at(i).set_surface(temp2);
                Charas_nps->at(i).dir = 0;
                Charas_nps->at(i).frame = 0;
                Charas_nps->at(i).move_dir=5;
                Charas_nps->at(i).move_frec=1;
                Charas_nps->at(i).anim_frec=1;
                Charas_nps->at(i).layer=3;
               // Charas_nps->at(i).setposXY(Events->at(i).X_position, Events->at(i).Y_position);
        }
        Ev_state->at(i).Active_page=current_page;
    }
}

int E_management::Active_page(stEventMap * Event)
{
    int i;
 for(i=(Event->vcPage.size()-1);i>=0;i--)
{
    if(is_Active(&(Event->vcPage[i].Page_conditions)))
    return(i);
}
return(-1);
}

bool E_management::is_Active(stPageConditionEventMap * Page_conditions)//page conditions
{
int cond=Page_conditions->Conditions;
if(cond==0)
return true;
if(((cond)&1)&&(!myteam->state_swich(Page_conditions->Switch_A_ID)))
return false;

if(((cond>>1)&1)&&(!myteam->state_swich(Page_conditions->Switch_B_ID)))
return false;

if(((cond>>2)&1)&&(!myteam->is_equal(Page_conditions->Variable_ID,Page_conditions->Variable_value)))
return false;

if((((cond>>3)&1))&&(!myteam->is_on_the_inventory(Page_conditions->Item)))
return false;

if((((cond>>4)&1))&&(!myteam->is_on_the_team(Page_conditions->Hero)))
return false;

/*si el sexto bit esta encendido y el temporalizadorno retorna false
*/
return true;

}

void E_management::init(Audio * audio,unsigned char * TheScene,Player_Team * TheTeam,std:: vector <stEventMap> * TheEvents, std:: vector <Chara> * TheCharas_nps,CActor * TheActor, map_data * Thedata,Chipset * the_chip,std:: vector <E_state> *Evn_state,Mv_management * Move_management)
{
    int i=0;
    Ev_state=Evn_state;
    std::string system_string;
    chip = the_chip;
    NScene = TheScene;
    myaudio = audio;
    myteam = TheTeam;
    Events = TheEvents;
    Charas_nps = TheCharas_nps;
    Actor = TheActor;
    Thedata = data;
    system_string.append("System/");
    system_string.append(TheTeam->data2.System_dat.System_graphic);
    system_string.append(".png");
    message_box = new CMessage(system_string.c_str());
    use_keyboard = false;
    tried_to_talk = false;
    Mov_management=Move_management;
    Sprite image;
    image.visible=false;
    image.setcols(1);
    image.setrows(1);
    SDL_Surface *temp2;
    temp2 = CreateSurface(1,1);
    image.set_surface(temp2);
    for(i=0;i<50;i++)
        images.push_back(image);
myteam->scroll_writed=false;
}

void E_management::update(SDL_Surface *Screen)
{
    int i;
    for(i=0;i<50;i++)
        images[i].draw(Screen);

    On_map_anim.draw(Screen);
    if (message_box->visible)
    {
        message_box->draw(Screen);
    }
}

void E_management::updatekey(bool *running)
{
    if (use_keyboard)
    {
        int temp;
         temp = Control::pop_LM();
        switch (temp)
        {
        default:
            /**/
            break;
        }
        temp = Control::pop_action();
        switch (temp)
        {
        case DECISION:
            tried_to_talk=true;
            break;

        case EXIT:
            (*running)=false;
            break;

        default:
            tried_to_talk=false;
            break;
        }


    }
}


void E_management::active_exec_comand(Event_comand * comand,int event_id, E_state * comand_id)
{
    static int timer=0;
    static float Xmove,Ymove;
    int i,j,x,y;
    std::string system_string;

    switch (comand->Comand)
    {
    case Message:
    case Add_line_to_message:
        use_keyboard = true;

        /* Continue to the next command */
        timer++;
        if ((message_box->done&&(timer>30) )&&tried_to_talk)
        {
            timer = 0;
            message_box->visible = false;
            comand_id->id_exe_actual++;
            comand_id->id_actual_active = false;
            tried_to_talk = false;
            use_keyboard = false;
        }
        break;
 case Wait:
        Event_comand_Wait * comand_Wait;
        comand_Wait=(Event_comand_Wait *)comand;
        timer++;
        if (timer>(comand_Wait->Length*10))
        {
            timer = 0;
            comand_id->id_exe_actual++;
            comand_id->id_actual_active = false;
            use_keyboard = false;
        }
        break;
    case Move_Picture:// 0xD670,
        Event_comand_Move_Picture * comand_Move_Picture;
        comand_Move_Picture=(Event_comand_Move_Picture *)comand;
        i=comand_Move_Picture->Picture_ID;
        if(comand_Move_Picture->By_Value)
        {
        x=(myteam->world_var[comand_Move_Picture->X]-(images[i-1].getw()/2));
        y=myteam->world_var[comand_Move_Picture->Y]-(images[i-1].geth()/2);
        }
        else
        {
        x=comand_Move_Picture->X-(images[i-1].getw()/2);
        y=comand_Move_Picture->Y-(images[i-1].geth()/2);
        }

        if(timer==0)
        {
        timer=(comand_Move_Picture->Length);
        Xmove=(x-images[i-1].x)/(comand_Move_Picture->Length);
        Ymove=(y-images[i-1].y)/(comand_Move_Picture->Length);
        }
        images[i-1].x+=Xmove;
        images[i-1].y+=Ymove;
        timer--;
        if(((x==images[i-1].x)&&(y==images[i-1].y))||(timer==0))
        {
        images[i-1].x=x;
        images[i-1].y=y;
        timer=0;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }

        break;
    case Show_Battle_Anim :// 0xD74A,
        if(On_map_anim.animation_ended)
        {
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        use_keyboard = false;
        }
        break;

    case Call_event:// 0xE02A,
        Event_comand_Call_event * comand_Call_event;
        comand_Call_event= (Event_comand_Call_event *)comand;
        if(comand_Call_event->Method==2)
        {
        i=myteam->world_var[comand_Call_event->Event_ID];
        j=myteam->world_var[comand_Call_event->Event_page];
        }
        if(comand_Call_event->Method==1)
        {
        i=comand_Call_event->Event_ID;
        j=comand_Call_event->Event_page;
        }
        if(Ev_state->at(i-1).Event_Active==false)
        {
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }
        break;
    case Pan_screen:// 0xD634,

        Event_comand_Pan_screen * comand_Pan_screen;
        comand_Pan_screen=(Event_comand_Pan_screen *)comand;
        if(comand_Pan_screen->Speed==1)
       x=1;
        if(comand_Pan_screen->Speed==2)
       x=2;
        if(comand_Pan_screen->Speed==3)
       x=3;
        if(comand_Pan_screen->Speed==4)
       x=4;
        if(comand_Pan_screen->Speed==5)
       x=8;
        if(comand_Pan_screen->Speed==6)
       x=16;

       if(comand_Pan_screen->Type==2)
       {
       if(timer ==0)
       {
      if(!myteam->scroll_writed)
       { myteam->original_scroll_x=myteam->view.x;
        myteam->original_scroll_y=myteam->view.y;
       myteam->scroll_writed=true;
       }
        Xmove=(comand_Pan_screen->Distance *16)/(x);// time
       }
       if(comand_Pan_screen->Direction==0)
       myteam->view.y-=x;
       if(comand_Pan_screen->Direction==1)
       myteam->view.x+=x;
       if(comand_Pan_screen->Direction==2)
       myteam->view.y+=x;
       if(comand_Pan_screen->Direction==3)
        myteam->view.x-=x;
       timer++;
       if(Xmove==timer)
        {
        timer=0;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }
       }

       if((comand_Pan_screen->Type==3)&&myteam->scroll_writed)
       {

       if(timer ==0)
       {
       if(myteam->original_scroll_x>myteam->original_scroll_y)
       {
       if(myteam->original_scroll_x>myteam->view.x)
        Xmove=(myteam->original_scroll_x-myteam->view.x)/(x);// time
       else
        Xmove=(myteam->view.x-myteam->original_scroll_x)/(x);// time
       }
       else
       {
        if(myteam->original_scroll_y>myteam->view.y)
        Xmove=(myteam->original_scroll_y-myteam->view.y)/(x);// time
        else
        Xmove=(myteam->view.y-myteam->original_scroll_y)/(x);// time
       }
       }

       if(myteam->view.y<myteam->original_scroll_y)
       myteam->view.y+=x;
       if(myteam->view.x<myteam->original_scroll_x)
       myteam->view.x+=x;
       if(myteam->view.y>myteam->original_scroll_y)
       myteam->view.y-=x;
       if(myteam->view.x>myteam->original_scroll_x)
        myteam->view.x-=x;

       timer++;

        if(Xmove==timer)
        {
       myteam->scroll_writed=false;
       myteam->scroll_active=true;
        timer=0;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }

       }
        break;

 case Move_event:// 0xD842,
        Event_comand_Move_event * comand_Move_event;
        comand_Move_event=(Event_comand_Move_event *)comand;
if(comand_Move_event->Target!=10001)
 {
        if(comand_Move_event->Target==10005)
        i=event_id;
        else
        {
            i=busque_real_id(comand_Move_event->Target);
        }
   //Charas_nps->at(i).move_frec=comand_Move_event->Frequency;



  if((comand_Move_event->comand_moves.size())>(timer))
  {
  if (!Charas_nps->at(i).move(Charas_nps->at(i).move_dir))//till time to move
  {
    switch (comand_Move_event->comand_moves[timer]->Comand)
        {
        case 0:
            if (((chip->CollisionAt(Charas_nps->at(i).GridX,Charas_nps->at(i).GridY,DIRECTION_UP))&&(Mov_management->npc_colision(Charas_nps->at(i).GridX, (Charas_nps->at(i).GridY-1),i)))||comand_Move_event->Ignore_impossible)
            {
            Charas_nps->at(i).move_dir=DIRECTION_UP;
            Charas_nps->at(i).GridY-=1;
            Charas_nps->at(i).state=true;
            }
            break;
        case 2:
            if (((chip->CollisionAt(Charas_nps->at(i).GridX,Charas_nps->at(i).GridY,DIRECTION_DOWN))&&(Mov_management->npc_colision(Charas_nps->at(i).GridX, (Charas_nps->at(i).GridY+1),i)))||comand_Move_event->Ignore_impossible)
            {
            Charas_nps->at(i).move_dir=DIRECTION_DOWN;
            Charas_nps->at(i).GridY+=1;
            Charas_nps->at(i).state=true;
            }
            break;
        case 3:
            if (((chip->CollisionAt(Charas_nps->at(i).GridX,Charas_nps->at(i).GridY,DIRECTION_LEFT))&&(Mov_management->npc_colision((Charas_nps->at(i).GridX-1), Charas_nps->at(i).GridY,i)))||comand_Move_event->Ignore_impossible)
             {
             Charas_nps->at(i).move_dir=DIRECTION_LEFT;
             Charas_nps->at(i).GridX-=1;
             Charas_nps->at(i).state=true;

             }
            break;
        case 1:
            if (((chip->CollisionAt(Charas_nps->at(i).GridX,Charas_nps->at(i).GridY,DIRECTION_RIGHT))&&(Mov_management->npc_colision((Charas_nps->at(i).GridX+1), Charas_nps->at(i).GridY,i)))||comand_Move_event->Ignore_impossible)
            {
            Charas_nps->at(i).move_dir=DIRECTION_RIGHT;
            Charas_nps->at(i).GridX+=1;
            Charas_nps->at(i).state=true;
            }
            break;
        case 34:
            Event_comand_Change_Hero_Graphic * comand_key1;
            comand_key1 =(Event_comand_Change_Hero_Graphic *)comand_Move_event->comand_moves[timer];
            system_string.clear();
            system_string.append("CharSet/");
            system_string.append(comand_key1->New_graphic);
            system_string.append(".png");
            Charas_nps->at(i).dispose();
            Charas_nps->at(i).setimg((char *) system_string.c_str(),comand_key1->Sprite_ID);
            break;

        }
  timer++;
  }
}else
  {
     Charas_nps->at(i).move_from_event=false;
        timer=0;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
}
 }
        break;

    default:
        break;
    }

}
void E_management::dispose()
{
    delete message_box;
    message_box=NULL;
    images.clear();
}

int E_management::busque_real_id(int id_to_serch)
{
    int i;
    for(i=0;i<Charas_nps->size();i++)
    if(Charas_nps->at(i).id==id_to_serch)
        return(i);
return(-1);
}

void E_management::exec_comand(std:: vector <Event_comand *> vcEvent_comand,int event_id, E_state * comand_id)
{
    int j,i;
    string system_string;
    Event_comand * comand,* Next_comand;
    comand=vcEvent_comand[comand_id->id_exe_actual];// lee el comando
    if(comand_id->id_exe_actual+1<vcEvent_comand.size())
    Next_comand=vcEvent_comand[comand_id->id_exe_actual+1];// lee el comando
    else
    Next_comand=NULL;
    static int line = 0;

    switch (comand->Comand)
    {
    case Message:
        line = 0;
        message_box->clean();
        Event_comand_Message *comand_Message;
        comand_Message= ( Event_comand_Message *)comand;
        use_keyboard=true;
        message_box->add_text(comand_Message->Text, line);
        message_box->visible = true;
        if((comand_id->id_exe_actual+1<vcEvent_comand.size())&&(Next_comand->Comand==Add_line_to_message))        //si hay otra linea  el comnado esta completo
        {
            comand_id->id_exe_actual++;
            comand_id->id_actual_active = false;
        }
        else       // si no hay otra linea el mensaje es completo
        message_box->done = true;
        line++;
        break;

    case Add_line_to_message:
        use_keyboard=true;
        Event_comand_Message * Add_line_to;
        Add_line_to= ( Event_comand_Message *)comand;
        message_box->add_text(Add_line_to->Text,line);
        line++;
        message_box->visible = true;

        if((comand_id->id_exe_actual+1<vcEvent_comand.size())&&(Next_comand->Comand==Add_line_to_message))        //si hay otra linea  el comnado esta completo
        {
            comand_id->id_exe_actual++;
            comand_id->id_actual_active = false;
        }
        else       // si no hay otra linea el mensaje es completo
        message_box->done = true;
        break;

    case Message_options:// 0xCF08,
        Event_comand_Message_options * comand_Message_options;
        comand_Message_options = (Event_comand_Message_options *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Select_message_face:// 0xCF12,
        Event_comand_Select_face * comand_Select_face;
        comand_Select_face = (Event_comand_Select_face *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Show_choice:// 0xCF1C,
        Event_comand_Show_choice * comand_Show_choice;
        comand_Show_choice = (Event_comand_Show_choice *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Nested_block:// 0x0A
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Show_choice_option:// 0x819D2C,
        Event_comand_Show_choice_option * comand_Show_choice_option;
        comand_Show_choice_option = (Event_comand_Show_choice_option *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case End_Choice_block:// 0x819D2D,
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Number_input:// 0xCF26,
        Event_comand_Number_input * comand_Number_input;
        comand_Number_input = (Event_comand_Number_input *)comand;

        break;
    case Change_switch:// 0xCF62,
        Event_comand_Change_switch * comand_Change_switch;
        comand_Change_switch = (Event_comand_Change_switch *)comand;
       if(comand_Change_switch->Mode<2)
      {
        for(j=comand_Change_switch->start_switch;j<=comand_Change_switch->end_switch;j++)
        {
            if(comand_Change_switch->toggle_option==0)
                myteam->set_true_swich(j);
            if(comand_Change_switch->toggle_option==1)
                myteam->set_false_swich(j);
            if(comand_Change_switch->toggle_option==2)
                if(myteam->state_swich(j))
                    myteam->set_false_swich(j);
                else
                    myteam->set_true_swich(j);
        }
      }
      else
      {
            j=  myteam->world_var[comand_Change_switch->start_switch];
            if(comand_Change_switch->toggle_option==0)
                myteam->set_true_swich(j);
            if(comand_Change_switch->toggle_option==1)
                myteam->set_false_swich(j);
            if(comand_Change_switch->toggle_option==2)
                if(myteam->state_swich(j))
                    myteam->set_false_swich(j);
                else
                    myteam->set_true_swich(j);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        page_refresh();
        break;
    case Change_var:// 0xCF6C,
            Event_comand_Change_var * comand_Change_var;
            comand_Change_var = (Event_comand_Change_var *)comand;

         switch(comand_Change_var->op_mode)
            {
            case 0:
            i=comand_Change_var->op_data1;
            printf("data to put %d",i);
                break;
            case 1:
            i= myteam->world_var[comand_Change_var->op_data1];
                break;
            case 2:
                break;
            case 3:
                break;
            case 4:
                break;
            case 5:
                break;
            case 6:
                break;
            default:
                break;
            }
        if(comand_Change_var->Mode<2)
      {

        for(j=comand_Change_var->start_switch;j<=comand_Change_var->end_switch;j++)
        {

            switch(comand_Change_var->operation)
            {
            case 0:
            myteam->world_var[j-1]=i;
                break;
            case 1:
            myteam->world_var[j-1]+=i;
            printf("variable usada %d",j);
                break;
            case 2:
            myteam->world_var[j-1]-=i;
                break;
            case 3:
            myteam->world_var[j-1]*=i;
                break;
            case 4:
            myteam->world_var[j-1]/=i;
                break;
            case 5:
            myteam->world_var[j-1]%=i;
                break;
            default:
                break;

            }


         }
      }
      else
      {
            j=  myteam->world_var[comand_Change_var->start_switch];

            switch(comand_Change_var->operation)
            {
            case 0:
            myteam->world_var[j-1]=i;
                break;
            case 1:
            myteam->world_var[j-1]+=i;
                break;
            case 2:
            myteam->world_var[j-1]-=i;
                break;
            case 3:
            myteam->world_var[j-1]*=i;
                break;
            case 4:
            myteam->world_var[j-1]/=i;
                break;
            case 5:
            myteam->world_var[j-1]%=i;
                break;
            default:
                break;

            }
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        page_refresh();
        break;
    case Timer_manipulation:// 0xCF76,
        Event_comand_Timer_manipulation * comand_Timer_manipulation;
        comand_Timer_manipulation = (Event_comand_Timer_manipulation *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_cash_held:// 0xD046,
        Event_comand_Change_cash_held * comand_Change_cash_held;
        comand_Change_cash_held = (Event_comand_Change_cash_held *)comand;
        j=myteam->get_Gold();
        if(comand_Change_cash_held->By_Value)
        {
         if(comand_Change_cash_held->Add)
            {
            j=j-myteam->world_var[comand_Change_cash_held->Amount-1];
            if(j<0)
            j=0;
            myteam->set_Gold(j);
            }
            else
            {
            j=j+myteam->world_var[comand_Change_cash_held->Amount-1];
            myteam->set_Gold(j);
            }

        }else
        {
            if(comand_Change_cash_held->Add)
            {
            j=j-comand_Change_cash_held->Amount;
            if(j<0)
            j=0;
            myteam->set_Gold(j);
            }
            else
            {
            j=j+comand_Change_cash_held->Amount;
            myteam->set_Gold(j);
            }
        }


        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_inventory:// 0xD050,
        Event_comand_Change_inventory * comand_Change_inventory;
        comand_Change_inventory = (Event_comand_Change_inventory *)comand;
        if(comand_Change_inventory->By_ID)
            i=myteam->world_var[comand_Change_inventory->Item_ID-1];
        else
            i=comand_Change_inventory->Item_ID;

        if(comand_Change_inventory->By_Count)
            j=myteam->world_var[comand_Change_inventory->Count-1];
        else
            j=comand_Change_inventory->Count;

        myteam->change_objets(comand_Change_inventory->Add,i,j);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_party:// 0xD05A,
        Event_comand_Change_party * comand_Change_party;
        comand_Change_party = (Event_comand_Change_party *)comand;

        if(comand_Change_party->By_ID)
            i=myteam->world_var[comand_Change_party->Hero_ID-1];
        else
            i=comand_Change_party->Hero_ID;

        myteam->change_players(comand_Change_party->Add,i);

        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_experience:// 0xD12A,
        Event_comand_Change_experience * comand_Change_experience;
        comand_Change_experience = (Event_comand_Change_experience *)comand;

        if(comand_Change_experience->By_Count)
            i=myteam->world_var[comand_Change_experience->Count-1];
        else
            i=comand_Change_experience->Count;

        if(comand_Change_experience->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_exp(comand_Change_experience->Add,myteam->Players[j].id, i);
            }
        }
        if(comand_Change_experience->All==1)
        {
            myteam->change_exp(comand_Change_experience->Add,comand_Change_experience->Hero_ID, i);
        }

        if(comand_Change_experience->All==2)
        {
            myteam->change_exp(comand_Change_experience->Add,myteam->world_var[comand_Change_experience->Hero_ID-1],i);
        }

        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_level:// 0xD134,
        Event_comand_Change_level * comand_Change_level;
        comand_Change_level = (Event_comand_Change_level *)comand;

        if(comand_Change_level->By_Count)
            i=myteam->world_var[comand_Change_level->Count-1];
        else
            i=comand_Change_level->Count;

        if(comand_Change_level->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_level(comand_Change_level->Add,myteam->Players[j].id, i);
            }
        }
        if(comand_Change_level->All==1)
        {
            myteam->change_level(comand_Change_level->Add,comand_Change_level->Hero_ID, i);
        }

        if(comand_Change_level->All==2)
        {
            myteam->change_level(comand_Change_level->Add,myteam->world_var[comand_Change_level->Hero_ID-1],i);
        }

        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_statistics:// 0xD13E,
        Event_comand_Change_statistics * comand_Change_statistics;
        comand_Change_statistics = (Event_comand_Change_statistics *)comand;


        if(comand_Change_statistics->By_Count)
            i=myteam->world_var[comand_Change_statistics->Count-1];
        else
            i=comand_Change_statistics->Count;

        if(comand_Change_statistics->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_stats(comand_Change_statistics->Add,myteam->Players[j].id, i, comand_Change_statistics->Stat);
            }
        }
        if(comand_Change_statistics->All==1)
        {
            myteam->change_stats(comand_Change_statistics->Add,comand_Change_statistics->Hero_ID, i, comand_Change_statistics->Stat);
        }

        if(comand_Change_statistics->All==2)
        {
            myteam->change_stats(comand_Change_statistics->Add,myteam->world_var[comand_Change_statistics->Hero_ID-1], i, comand_Change_statistics->Stat);
        }

        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Learn_forget_skill:// 0xD148,
        Event_comand_Learn_forget_skill * comand_Learn_forget_skill;
        comand_Learn_forget_skill = (Event_comand_Learn_forget_skill *)comand;

        if(comand_Learn_forget_skill->By_Count)
            i=myteam->world_var[comand_Learn_forget_skill->Count-1];
        else
            i=comand_Learn_forget_skill->Count;

        if(comand_Learn_forget_skill->Hero==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_skills(comand_Learn_forget_skill->Learn,myteam->Players[j].id, i);
            }
        }
        if(comand_Learn_forget_skill->Hero==1)
        {
            myteam->change_skills(comand_Learn_forget_skill->Learn,comand_Learn_forget_skill->Hero_ID, i);
        }
        if(comand_Learn_forget_skill->Hero==2)
        {
            myteam->change_skills(comand_Learn_forget_skill->Learn,myteam->world_var[comand_Learn_forget_skill->Hero_ID-1],i);
        }

        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_equipment:// 0xD152,
        Event_comand_Change_equipment * comand_Change_equipment;
        comand_Change_equipment = (Event_comand_Change_equipment *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_HP:// 0xD15C,
        Event_comand_Change_HP * comand_Change_HP;
        comand_Change_HP = (Event_comand_Change_HP *)comand;

        if(comand_Change_HP->By_Count)
            i=myteam->world_var[comand_Change_HP->Count-1];
        else
            i=comand_Change_HP->Count;

        if(comand_Change_HP->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_HP(comand_Change_HP->Add,myteam->Players[j].id, i);
            }
        }
        if(comand_Change_HP->All==1)
        {
            myteam->change_HP(comand_Change_HP->Add,comand_Change_HP->Hero_ID, i);
        }

        if(comand_Change_HP->All==2)
        {
            myteam->change_HP(comand_Change_HP->Add,myteam->world_var[comand_Change_HP->Hero_ID-1],i);
        }


        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_MP:// 0xD166,
        Event_comand_Change_MP * comand_Change_MP;
        comand_Change_MP = (Event_comand_Change_MP *)comand;
        if(comand_Change_MP->By_Count)
            i=myteam->world_var[comand_Change_MP->Count-1];
        else
            i=comand_Change_MP->Count;

        if(comand_Change_MP->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->change_MP(comand_Change_MP->Add,myteam->Players[j].id, i);
            }
        }
        if(comand_Change_MP->All==1)
        {
            myteam->change_MP(comand_Change_MP->Add,comand_Change_MP->Hero_ID, i);
        }

        if(comand_Change_MP->All==2)
        {
            myteam->change_MP(comand_Change_MP->Add,myteam->world_var[comand_Change_MP->Hero_ID-1],i);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Change_Status:// 0xD170,
        Event_comand_Change_Status * comand_Change_Status;
        comand_Change_Status = (Event_comand_Change_Status *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Full_Recovery:// 0xD17A,
        Event_comand_Full_Recovery * comand_Full_Recovery;
        comand_Full_Recovery = (Event_comand_Full_Recovery *)comand;

        if(comand_Full_Recovery->All==0)
        {
            for(j=0;j<myteam->Players.size();j++)
            {
            myteam->Full_Recovery(myteam->Players[j].id);
            }
        }
        if(comand_Full_Recovery->All==1)
        {
            myteam->Full_Recovery(comand_Full_Recovery->Hero_ID);
        }

        if(comand_Full_Recovery->All==2)
        {
            myteam->Full_Recovery(myteam->world_var[comand_Full_Recovery->Hero_ID-1]);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Inflict_Damage:// 0xD204,
        Event_comand_Inflict_Damage * comand_Inflict_Damage;
        comand_Inflict_Damage = (Event_comand_Inflict_Damage *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_Hero_Name:// 0xD272,
        Event_comand_Change_Hero_Name * comand_Change_Hero_Name;
        comand_Change_Hero_Name = (Event_comand_Change_Hero_Name * )comand;
        myteam->change_name(comand_Change_Hero_Name->Hero_ID,comand_Change_Hero_Name->New_name.c_str());
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        break;
    case Change_Hero_Class:// 0xD27C,
        Event_comand_Change_Hero_Class * comand_Change_Hero_Class;
        comand_Change_Hero_Class = (Event_comand_Change_Hero_Class *)comand;
        myteam->change_class(comand_Change_Hero_Class->Hero_ID,comand_Change_Hero_Class->strNew_class.c_str());
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        break;
    case Change_Hero_Graphic:// 0xD306,
        Event_comand_Change_Hero_Graphic * comand_Change_Hero_Graphic;
        comand_Change_Hero_Graphic = (Event_comand_Change_Hero_Graphic *)comand;
        system_string.append("CharSet/");
        system_string.append(comand_Change_Hero_Graphic->New_graphic.c_str());
        system_string.append(".png");

        myteam->change_graphic(comand_Change_Hero_Graphic->Hero_ID,system_string.c_str(),comand_Change_Hero_Graphic->Sprite_ID);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        break;
    case Change_Hero_Face:// 0xD310,
        Event_comand_Change_Hero_Face * comand_Change_Hero_Face;
        comand_Change_Hero_Face = (Event_comand_Change_Hero_Face *)comand;

        system_string.append("FaceSet/");
        system_string.append(comand_Change_Hero_Face->New_graphic.c_str());
        system_string.append(".png");

        myteam->change_face(comand_Change_Hero_Face->Hero_ID,system_string.c_str(),comand_Change_Hero_Face->Face_ID);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        break;
    case Change_Vehicle:// 0xD31A,
        Event_comand_Change_Vehicle * comand_Change_Vehicle;
        comand_Change_Vehicle = (Event_comand_Change_Vehicle *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_System_BGM:// 0xD324,
        Event_comand_Change_System_BGM * comand_Change_System_BGM;
        comand_Change_System_BGM = (Event_comand_Change_System_BGM *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_System_SE:// 0xD32E,
        Event_comand_Change_System_SE * comand_Change_System_SE;
        comand_Change_System_SE = (Event_comand_Change_System_SE *)comand;
      comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_System_GFX:// 0xD338,
        Event_comand_Change_System_GFX * comand_Change_System_GFX;
        comand_Change_System_GFX= (Event_comand_Change_System_GFX *)comand;
        myteam->data2.System_dat.System_graphic=comand_Change_System_GFX->New_graphic;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        break;
    case Change_Transition:// 0xD342,
        Event_comand_Change_Transition * comand_Change_Transition;
        comand_Change_Transition = (Event_comand_Change_Transition *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Start_Combat:// 0xD356,
        Event_comand_Start_Combat * comand_Start_Combat;
        comand_Start_Combat = (Event_comand_Start_Combat*)comand;
        /*
        if ((Key_press_and_realsed(LMK_Z )) &&(npc.colision((*player))))
        {
        Enemy enemigo;
        enemigo.set_HP(20);
        enemigo.set_MaxHP(20);
        enemigo.set_MP(200);
        enemigo.set_MaxMP(200);
        enemigo.set_Attack(12);
        enemigo.set_Defense(50);
        enemigo.set_Speed(25);
        enemigo.set_Spirit(20);
        (enemigo.Batler).setimg("Monster/Slime.png");
        (enemigo.Batler).setcols(1);
        (enemigo.Batler).setrows(1);
        (enemigo.Batler).x=140;
        (enemigo.Batler).y=100;
        enemigo.set_name("Limo");
        (*myteam).add_enemy(enemigo);
        enemigo.set_name("Murici");
        enemigo.set_HP(300);
        enemigo.set_MaxHP(30);
        (enemigo.Batler).setimg("Monster/Bat.png");
        (enemigo.Batler).x=80;
        (enemigo.Batler).y=100;
        (*myteam).add_enemy(enemigo);
        enemigo.set_HP(35);
        enemigo.set_MaxHP(35);
        enemigo.set_name("Araña");
        (enemigo.Batler).setimg("Monster/Spider.png");
        (enemigo.Batler).x=180;
        (enemigo.Batler).y=100;
        (*myteam).add_enemy(enemigo);
        enemigo.set_HP(20);
        enemigo.set_MaxHP(20);
        enemigo.set_name("Avispón");
        (enemigo.Batler).setimg("Monster/Bee.png");
        (enemigo.Batler).x=140;
        (enemigo.Batler).y=60;
        (*myteam).add_enemy(enemigo);
        * NScene=2;
        }*/
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;

    case Call_Shop:// 0xD360,
        Event_comand_Call_Shop * comand_Call_Shop;
        comand_Call_Shop = (Event_comand_Call_Shop*)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Start_success_block:// 0x81A170,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Start_failure_block:// 0x81A171,
    comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case End_shop_block:// 0x81A172,
    comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;

    case Call_Inn:// 0xD36A,
        Event_comand_Call_Inn * comand_Call_Inn;
        comand_Call_Inn = (Event_comand_Call_Inn*)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Start_success_block2:// 0x81A17A,
    comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Start_failure_block2:// 0x81A17B,
    comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case End_block:// 0x81A17C,
    comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Enter_hero_name:// 0xD374,
        Event_comand_Enter_hero_name * comand_Enter_hero_name;
        comand_Enter_hero_name =(Event_comand_Enter_hero_name *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Teleport_Party:
        Event_comand_Teleport_Party * command_Teleport_Party;
        command_Teleport_Party= ( Event_comand_Teleport_Party *)comand;
        myteam->actual_map=command_Teleport_Party->Map_ID;
        myteam->actual_x_map=command_Teleport_Party->X;
        myteam->actual_y_map=command_Teleport_Party->Y;
        Actor->setposXY(myteam->actual_x_map,myteam->actual_y_map);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Store_hero_location:// 0xD444,
        Event_comand_Store_hero_location * comand_Store_hero_location;
        comand_Store_hero_location=(Event_comand_Store_hero_location *)comand;
        myteam->world_var[comand_Store_hero_location->Map_ID_Var-1]=myteam->actual_map;
        myteam->world_var[comand_Store_hero_location->X_Var-1]=Actor->GridX;
        myteam->world_var[comand_Store_hero_location->Y_Var-1]=Actor->GridY;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Recall_to_location:// 0xD44E,
        Event_comand_Recall_to_location * comand_Recall_to_location;
        comand_Recall_to_location=(Event_comand_Recall_to_location *)comand;
        myteam->actual_map=myteam->world_var[comand_Recall_to_location->Map_ID_Var-1];
        myteam->actual_x_map=myteam->world_var[(comand_Recall_to_location->X_Var-1)];
        myteam->actual_y_map=myteam->world_var[(comand_Recall_to_location->Y_Var-1)];
        Actor->setposXY(myteam->actual_x_map,myteam->actual_y_map);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Ride_Dismount:// 0xD458	,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Teleport_Vehicle:// 0xD462,
        Event_comand_Teleport_Vehicle * comand_Teleport_Vehicle;
        comand_Teleport_Vehicle=(Event_comand_Teleport_Vehicle *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Teleport_Event:// 0xD46C,
        Event_comand_Teleport_Event * comand_Teleport_Event;
        comand_Teleport_Event=(Event_comand_Teleport_Event *)comand;
        for(i=0;i<Charas_nps->size();i++)
        {
            if(Charas_nps->at(i).id==comand_Teleport_Event->Event_ID)
            {
                j=i;
                break;
            }
        }
        if(j<Charas_nps->size())
        {
        if(comand_Teleport_Event->By_value)
        {
            Charas_nps->at(j).setposXY(myteam->world_var[comand_Teleport_Event->X-1],myteam->world_var[comand_Teleport_Event->Y-1]);
        }else
        {
            Charas_nps->at(j).setposXY(comand_Teleport_Event->X,comand_Teleport_Event->Y);
        }
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Swap_Event_Positions:// 0xD476,
        Event_comand_Swap_Event_Positions * comand_Swap_Event_Positions;
        comand_Swap_Event_Positions=(Event_comand_Swap_Event_Positions *)comand;
        int x1,y1;
        if(comand_Swap_Event_Positions->First_event!=10005)
        for(i=0;i<Charas_nps->size();i++)
        {
            if(Charas_nps->at(i).id==comand_Swap_Event_Positions->First_event)
            {
                break;
            }
        }
        if((i<Charas_nps->size())||(comand_Swap_Event_Positions->First_event==10005))
        {
        if(comand_Swap_Event_Positions->First_event==10005)
        i=event_id;

        x1=Charas_nps->at(i).GridX;
        y1=Charas_nps->at(i).GridY;

        if(comand_Swap_Event_Positions->Second_event!=10005)
        for(j=0;j<Charas_nps->size();j++)
        {
            if(Charas_nps->at(j).id==comand_Swap_Event_Positions->Second_event)
            {
                break;
            }
        }

        if((j<Charas_nps->size())||(comand_Swap_Event_Positions->Second_event==10005))
        {
        if(comand_Swap_Event_Positions->Second_event==10005)
        j=event_id;

        Charas_nps->at(i).setposXY(Charas_nps->at(j).GridX,Charas_nps->at(j).GridY);
        Charas_nps->at(j).setposXY(x1,y1);
        }
        }

        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Get_Terrain_ID:// 0xD51E,
        Event_comand_Get_Terrain_ID * comand_Get_Terrain_ID;
        comand_Get_Terrain_ID=(Event_comand_Get_Terrain_ID *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Get_Event_ID:// 0xD528,
        Event_comand_Get_Event_ID * comand_Get_Event_ID;
        comand_Get_Event_ID=(Event_comand_Get_Event_ID *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Erase_screen:// 0xD602,
        Event_comand_Erase_screen * comand_Erase_screen;
        comand_Erase_screen=(Event_comand_Erase_screen *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Show_screen:// 0xD60C,
        Event_comand_Show_screen * comand_Show_screen;
        comand_Show_screen=(Event_comand_Show_screen *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Set_screen_tone:// 0xD616,
        Event_comand_Set_screen_tone * comand_Set_screen_tone;
        comand_Set_screen_tone=(Event_comand_Set_screen_tone *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Flash_screen:// 0xD620,
        Event_comand_Flash_screen * comand_Flash_screen;
        comand_Flash_screen=(Event_comand_Flash_screen *)comand;

        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Shake_screen:// 0xD62A,
        Event_comand_Shake_screen * comand_Shake_screen;
        comand_Shake_screen=(Event_comand_Shake_screen *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Pan_screen:// 0xD634,

        Event_comand_Pan_screen * comand_Pan_screen;
        comand_Pan_screen=(Event_comand_Pan_screen *)comand;
       if(comand_Pan_screen->Type==0)
       {
        myteam->scroll_active=false;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
       }
       if(comand_Pan_screen->Type==1)
       {
        myteam->scroll_active=true;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
       }

       if(comand_Pan_screen->Type>1)
       {
        myteam->scroll_active=false;

        }
        break;
    case Weather_Effects:// 0xD63E,
        Event_comand_Weather_Effects * comand_Weather_Effects;
        comand_Weather_Effects=(Event_comand_Weather_Effects *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Show_Picture:// 0xD666,
        Event_comand_Show_Picture * comand_Show_Picture;
        comand_Show_Picture=(Event_comand_Show_Picture *)comand;

        system_string.append("Picture/");
        system_string.append(comand_Show_Picture->Image_file.c_str());
        system_string.append(".png");

        i= comand_Show_Picture->Picture_ID;

        images[i-1].setimg(system_string.c_str());

        if(comand_Show_Picture->By_Value)
        {
        images[i-1].x=myteam->world_var[comand_Show_Picture->X]-(images[i-1].getw()/2);
        images[i-1].y=myteam->world_var[comand_Show_Picture->Y]-(images[i-1].geth()/2);
        }
        else
        {
        images[i-1].x=comand_Show_Picture->X-(images[i-1].getw()/2);
        images[i-1].y=comand_Show_Picture->Y-(images[i-1].geth()/2);
        }

        images[i-1].visible=true;


        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Move_Picture:// 0xD670,
        Event_comand_Move_Picture * comand_Move_Picture;
        comand_Move_Picture=(Event_comand_Move_Picture *)comand;
        i=comand_Move_Picture->Picture_ID;
        if(comand_Move_Picture->Length==0)
        {
        if(comand_Move_Picture->By_Value)
        {
        images[i-1].x=myteam->world_var[comand_Move_Picture->X]-(images[i-1].getw()/2);
        images[i-1].y=myteam->world_var[comand_Show_Picture->Y]-(images[i-1].geth()/2);
        }
        else
        {
        images[i-1].x=comand_Move_Picture->X-(images[i-1].getw()/2);
        images[i-1].y=comand_Move_Picture->Y-(images[i-1].geth()/2);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }
        break;
    case Erase_Picture:// 0xD67A,
        Event_comand_Erase_Picture * comand_Erase_Picture;
        comand_Erase_Picture=(Event_comand_Erase_Picture *)comand;
        i=comand_Erase_Picture->Picture_ID;
        images[i-1].visible=false;
        images[i-1].dispose();
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Show_Battle_Anim :// 0xD74A,
        Event_comand_Show_Battle_Anim * comand_Show_Battle_Anim;
        comand_Show_Battle_Anim=(Event_comand_Show_Battle_Anim *)comand;
        i=comand_Show_Battle_Anim->Animation_ID-1;
        On_map_anim.init_Anim(&myteam->data2.Animations[i],&myteam->S_manager);
        if(comand_Show_Battle_Anim->Target<10000)
        {
        j= busque_real_id(comand_Show_Battle_Anim->Target);
        On_map_anim.center_X=   Charas_nps->at(j).x+16;
        On_map_anim.center_Y=   Charas_nps->at(j).y+12;
        }
        if(comand_Show_Battle_Anim->Target==10001)
        {
        On_map_anim.center_X=   Actor->x+16;
        On_map_anim.center_Y=   Actor->y+12;
        }
        if(comand_Show_Battle_Anim->Target==10005)
        {
        On_map_anim.center_X=   Charas_nps->at(event_id).x+16;
        On_map_anim.center_Y=   Charas_nps->at(event_id).y+12;
        }


        if(comand_Show_Battle_Anim->Full_screen)
        {
        On_map_anim.center_X=160;
        On_map_anim.center_Y=120;
        }
        if(!comand_Show_Battle_Anim->Wait)
        {
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        }else
        {
        use_keyboard = true;
        }
        break;
    case Set_hero_opacity:// 0xD82E,
        Event_comand_Set_hero_opacity * comand_Set_hero_opacity;
        comand_Set_hero_opacity=(Event_comand_Set_hero_opacity *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Flash_event:// 0xD838,
        Event_comand_Flash_event * comand_Flash_event;
        comand_Flash_event=(Event_comand_Flash_event *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Move_event:// 0xD842,
        Event_comand_Move_event * comand_Move_event;
        comand_Move_event=(Event_comand_Move_event *)comand;
        cout<<"original"<<comand_Move_event->Target;
        if(comand_Move_event->Target!=10001)
        {
        if(comand_Move_event->Target==10005)
        i=event_id;
        else
        {
            i=busque_real_id(comand_Move_event->Target);
        }
        Charas_nps->at(i).move_from_event=true;
        }else
        {
        Actor->move_from_event=true;

        }
        break;
    case Wait_until_moved:// 0xD84C,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Stop_all_movement:// 0xD856,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Wait:// 0xD912,
         use_keyboard = true;

        break;
    case Play_BGM:// 0xD976,
        Event_comand_Play_BGM * comand_Play_BGM;
        comand_Play_BGM=(Event_comand_Play_BGM *)comand;
        system_string.clear();
        system_string.append("Music/");
        system_string.append(comand_Play_BGM->BGM_name.c_str());
        system_string.append(".mid");

        if(myaudio->actual_music.compare((char *)system_string.c_str()))
        {
            myaudio->load((char *)system_string.c_str());
            myaudio->play(-1);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Fade_out_BGM:// 0xDA00,
        Event_comand_Fade_out_BGM * comand_Fade_out_BGM;
        comand_Fade_out_BGM=(Event_comand_Fade_out_BGM *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Memorize_BGM:// 0xDA0A,
        myteam->memorized_BGM.clear();
        myteam->memorized_BGM.append(myaudio->actual_music.c_str());

        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Play_memorized:// 0xDA14,
        if(myaudio->actual_music.compare((char *)myteam->memorized_BGM.c_str()))
        {
            myaudio->load((char *)myteam->memorized_BGM.c_str());
            myaudio->play(-1);
        }
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Play_sound_effect:// 0xDA1E,
        Event_comand_Play_SE * comand_Play_SE;
        comand_Play_SE=(Event_comand_Play_SE *)comand;
        system_string.clear();
        system_string.append("Sound/");
        system_string.append(comand_Play_SE->SE_name.c_str());
        system_string.append(".wav");
        i=myteam->S_manager.load_sound((char *)system_string.c_str());
        myteam->S_manager.play_sound(i);
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Play_movie:// 0xDA28,
        Event_comand_Play_movie * comand_Play_movie;
        comand_Play_movie=(Event_comand_Play_movie *)comand;
                comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Key_input:// 0xDA5A,
        Event_comand_Key_input * comand_Key_input;
        comand_Key_input=(Event_comand_Key_input *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_tile_set:// 0xDB3E	,
        Event_comand_Change_tile * comand_Change_tile;
        comand_Change_tile=(Event_comand_Change_tile *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_background:// 0xDB48,
        Event_comand_Change_background * comand_Change_background;
        comand_Change_background=(Event_comand_Change_background *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Change_encounter_rate:
        Event_comand_Change_encounter_rate * command_Change_encounter_rate;
        command_Change_encounter_rate= ( Event_comand_Change_encounter_rate *)comand;
        myteam->Encounter_rate=command_Change_encounter_rate->Encounter_rate;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Change_single_tile:// 0xDB66,
        Event_comand_Change_single_tile * comand_Change_single_tile;
        comand_Change_single_tile=(Event_comand_Change_single_tile*)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Set_teleport_location:// 0xDC22,
        Event_comand_Set_teleport_location * comand_Set_teleport_location;
        comand_Set_teleport_location = (Event_comand_Set_teleport_location*)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Enable_teleport:
        Event_comand_Enable_teleport * comand_Enable_teleport;
        comand_Enable_teleport= (Event_comand_Enable_teleport *)comand;
        myteam->able_to_teleport=comand_Enable_teleport->Enable;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Set_escape_location:// 0xDC36,
        Event_comand_Set_escape_location * comand_Set_escape_location;
        comand_Set_escape_location=(Event_comand_Set_escape_location *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Enable_escape:
        Event_comand_Enable_escape * comand_Enable_escape;
        comand_Enable_escape= (Event_comand_Enable_escape *) comand;
        myteam->able_to_escape=comand_Enable_escape->Enable;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Call_save_menu:
        myteam->actual_x_map=Actor->GridX;
        myteam->actual_y_map=Actor->GridY;
        myteam->actual_dir=Actor->get_dir();
        *NScene = 9;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Enable_saving:
        Event_comand_Enable_saving * comand_Enable_saving;
        comand_Enable_saving= (Event_comand_Enable_saving *) comand;
        myteam->able_to_save=comand_Enable_saving->Enable;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Call_system_menu:
        myteam->actual_x_map=Actor->GridX;
        myteam->actual_y_map=Actor->GridY;
        myteam->actual_dir=Actor->get_dir();
        *NScene = 4;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Enable_system_menu:
        Event_comand_Enable_system_menu * comand_Enable_system_menu;
        comand_Enable_system_menu= (Event_comand_Enable_system_menu *) comand;
        myteam->able_to_menu=comand_Enable_system_menu->Enable;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Conditional:// 0xDD6A,
        Event_comand_Conditional * comand_Conditional;
        comand_Conditional= (Event_comand_Conditional *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Else_case:// 0x81AB7A,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case End_conditional:// 0x81AB7B,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Label:// 0xDE4E,
        Event_comand_Label * comand_Label;
        comand_Label = (Event_comand_Label *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Go_to_label:// 0xDE58,
        Event_comand_Go_to_label * comand_Go_to_label;
        comand_Go_to_label = (Event_comand_Go_to_label *)comand;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;

        break;
    case Start_loop:// 0xDF32,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case End_loop:// 0x81AD42,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Break:// 0xDF3C,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Stop_all_events:// 0xE016,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Delete_event:
        Charas_nps->at(event_id).GridX= data->MapHeight;
        Charas_nps->at(event_id).GridY= data->MapWidth;
        Charas_nps->at(event_id).layer= 3;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Call_event:// 0xE02A,
        Event_comand_Call_event * comand_Call_event;
        comand_Call_event= (Event_comand_Call_event *)comand;
        if(comand_Call_event->Method==0)//ignore
        {
        comand_id->id_exe_actual++;
        comand_id->id_actual_active = false;
        }
        if(comand_Call_event->Method==2)
        {
        i=myteam->world_var[comand_Call_event->Event_ID];
        j=myteam->world_var[comand_Call_event->Event_page];
        }
        if(comand_Call_event->Method==1)
        {
        i=comand_Call_event->Event_ID;
        j=comand_Call_event->Event_page;
        }
        if((comand_Call_event->Method==1)||(comand_Call_event->Method==2))
        {
        Ev_state->at(i-1).Event_Active=true;
        Ev_state->at(i-1).id_exe_actual=0;
        Ev_state->at(i-1).id_actual_active=false;
        Ev_state->at(i-1).Active_page=(j-1);
        }

        break;
    case Comment:// 0xE07A,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Add_line_to_comment:// 0x81AF0A,
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;

        break;
    case Game_over:
        *NScene = 3;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;
    case Return_to_title_screen:
        *NScene = 0;
        comand_id->id_exe_actual++;
        comand_id->id_actual_active=false;
        break;



    }
}

