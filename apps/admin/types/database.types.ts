export type Json =
  | string
  | number
  | boolean
  | null
  | { [key: string]: Json | undefined }
  | Json[];

export type AppRole = 'student' | 'admin' | 'super_admin';
export type VideoProvider = 'youtube' | 'bunny' | 'none';
export type MaterialType = 'lecture_sheet' | 'class_note' | 'other';
export type MaterialSource = 'drive' | 'storage' | 'rich_text';
export type ExamScope = 'lesson' | 'chapter' | 'subject';
export type ExamMode = 'practice' | 'live';
export type AnswerVisibility = 'immediately' | 'after_end' | 'never';
export type AttemptStatus = 'in_progress' | 'submitted' | 'expired';
export type DifficultyLevel = 'easy' | 'medium' | 'hard';

export interface Database {
  public: {
    Tables: {
      levels: {
        Row: {
          id: string;
          name: string;
          name_en: string | null;
          slug: string;
          description: string | null;
          icon_url: string | null;
          sort_order: number;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          name: string;
          name_en?: string | null;
          slug: string;
          description?: string | null;
          icon_url?: string | null;
          sort_order?: number;
          is_published?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['levels']['Insert']>;
        Relationships: [];
      };
      profiles: {
        Row: {
          id: string;
          full_name: string | null;
          avatar_url: string | null;
          phone: string | null;
          institution: string | null;
          level_id: string | null;
          locale: string;
          is_blocked: boolean;
          onboarded: boolean;
          last_seen_at: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id: string;
          full_name?: string | null;
          avatar_url?: string | null;
          phone?: string | null;
          institution?: string | null;
          level_id?: string | null;
          locale?: string;
          is_blocked?: boolean;
          onboarded?: boolean;
          last_seen_at?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['profiles']['Insert']>;
        Relationships: [];
      };
      user_roles: {
        Row: {
          user_id: string;
          role: AppRole;
          granted_by: string | null;
          created_at: string;
        };
        Insert: {
          user_id: string;
          role?: AppRole;
          granted_by?: string | null;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['user_roles']['Insert']>;
        Relationships: [];
      };
      subjects: {
        Row: {
          id: string;
          level_id: string;
          name: string;
          name_en: string | null;
          slug: string;
          description: string | null;
          icon_url: string | null;
          color_hex: string | null;
          sort_order: number;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          level_id: string;
          name: string;
          name_en?: string | null;
          slug: string;
          description?: string | null;
          icon_url?: string | null;
          color_hex?: string | null;
          sort_order?: number;
          is_published?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['subjects']['Insert']>;
        Relationships: [];
      };
      chapters: {
        Row: {
          id: string;
          subject_id: string;
          chapter_no: number | null;
          title: string;
          description: string | null;
          sort_order: number;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          subject_id: string;
          chapter_no?: number | null;
          title: string;
          description?: string | null;
          sort_order?: number;
          is_published?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['chapters']['Insert']>;
        Relationships: [];
      };
      lessons: {
        Row: {
          id: string;
          chapter_id: string;
          title: string;
          description: string | null;
          video_provider: VideoProvider;
          video_ref: string | null;
          video_duration_sec: number | null;
          thumbnail_url: string | null;
          instructor_name: string | null;
          sort_order: number;
          is_premium: boolean;
          is_published: boolean;
          published_at: string | null;
          created_by: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          chapter_id: string;
          title: string;
          description?: string | null;
          video_provider?: VideoProvider;
          video_ref?: string | null;
          video_duration_sec?: number | null;
          thumbnail_url?: string | null;
          instructor_name?: string | null;
          sort_order?: number;
          is_premium?: boolean;
          is_published?: boolean;
          published_at?: string | null;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['lessons']['Insert']>;
        Relationships: [];
      };
      materials: {
        Row: {
          id: string;
          lesson_id: string;
          type: MaterialType;
          source: MaterialSource;
          title: string;
          drive_file_id: string | null;
          storage_path: string | null;
          content_md: string | null;
          file_size_bytes: number | null;
          page_count: number | null;
          allow_download: boolean;
          sort_order: number;
          is_published: boolean;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          lesson_id: string;
          type: MaterialType;
          source: MaterialSource;
          title: string;
          drive_file_id?: string | null;
          storage_path?: string | null;
          content_md?: string | null;
          file_size_bytes?: number | null;
          page_count?: number | null;
          allow_download?: boolean;
          sort_order?: number;
          is_published?: boolean;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['materials']['Insert']>;
        Relationships: [];
      };
      questions: {
        Row: {
          id: string;
          chapter_id: string;
          body: string;
          image_url: string | null;
          explanation: string | null;
          explanation_image_url: string | null;
          difficulty: DifficultyLevel;
          tags: string[];
          source_ref: string | null;
          created_by: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          chapter_id: string;
          body: string;
          image_url?: string | null;
          explanation?: string | null;
          explanation_image_url?: string | null;
          difficulty?: DifficultyLevel;
          tags?: string[];
          source_ref?: string | null;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['questions']['Insert']>;
        Relationships: [];
      };
      question_options: {
        Row: {
          id: string;
          question_id: string;
          body: string;
          image_url: string | null;
          is_correct: boolean;
          sort_order: number;
        };
        Insert: {
          id?: string;
          question_id: string;
          body: string;
          image_url?: string | null;
          is_correct?: boolean;
          sort_order?: number;
        };
        Update: Partial<Database['public']['Tables']['question_options']['Insert']>;
        Relationships: [];
      };
      exams: {
        Row: {
          id: string;
          title: string;
          description: string | null;
          instructions: string | null;
          scope: ExamScope;
          subject_id: string;
          chapter_id: string | null;
          lesson_id: string | null;
          mode: ExamMode;
          duration_sec: number;
          mark_per_question: number;
          negative_mark: number;
          pass_percentage: number;
          shuffle_questions: boolean;
          shuffle_options: boolean;
          max_attempts: number | null;
          answer_visibility: AnswerVisibility;
          starts_at: string | null;
          ends_at: string | null;
          is_premium: boolean;
          is_published: boolean;
          created_by: string | null;
          created_at: string;
          updated_at: string;
        };
        Insert: {
          id?: string;
          title: string;
          description?: string | null;
          instructions?: string | null;
          scope: ExamScope;
          subject_id: string;
          chapter_id?: string | null;
          lesson_id?: string | null;
          mode?: ExamMode;
          duration_sec: number;
          mark_per_question?: number;
          negative_mark?: number;
          pass_percentage?: number;
          shuffle_questions?: boolean;
          shuffle_options?: boolean;
          max_attempts?: number | null;
          answer_visibility?: AnswerVisibility;
          starts_at?: string | null;
          ends_at?: string | null;
          is_premium?: boolean;
          is_published?: boolean;
          created_by?: string | null;
          created_at?: string;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['exams']['Insert']>;
        Relationships: [];
      };
      exam_questions: {
        Row: {
          exam_id: string;
          question_id: string;
          sort_order: number;
        };
        Insert: {
          exam_id: string;
          question_id: string;
          sort_order?: number;
        };
        Update: Partial<Database['public']['Tables']['exam_questions']['Insert']>;
        Relationships: [];
      };
      exam_attempts: {
        Row: {
          id: string;
          exam_id: string;
          user_id: string;
          attempt_no: number;
          status: AttemptStatus;
          started_at: string;
          deadline_at: string;
          submitted_at: string | null;
          question_order: string[];
          option_order: Json;
          total_questions: number;
          total_marks: number;
          correct_count: number | null;
          wrong_count: number | null;
          skipped_count: number | null;
          score: number | null;
          percentage: number | null;
          is_passed: boolean | null;
          time_taken_sec: number | null;
        };
        Insert: {
          id?: string;
          exam_id: string;
          user_id: string;
          attempt_no: number;
          status?: AttemptStatus;
          started_at?: string;
          deadline_at: string;
          submitted_at?: string | null;
          question_order: string[];
          option_order?: Json;
          total_questions: number;
          total_marks: number;
          correct_count?: number | null;
          wrong_count?: number | null;
          skipped_count?: number | null;
          score?: number | null;
          percentage?: number | null;
          is_passed?: boolean | null;
          time_taken_sec?: number | null;
        };
        Update: Partial<Database['public']['Tables']['exam_attempts']['Insert']>;
        Relationships: [];
      };
      announcements: {
        Row: {
          id: string;
          level_id: string | null;
          title: string;
          body: string;
          image_url: string | null;
          deep_link: string | null;
          is_pinned: boolean;
          is_published: boolean;
          published_at: string | null;
          expires_at: string | null;
          created_by: string | null;
          created_at: string;
        };
        Insert: {
          id?: string;
          level_id?: string | null;
          title: string;
          body: string;
          image_url?: string | null;
          deep_link?: string | null;
          is_pinned?: boolean;
          is_published?: boolean;
          published_at?: string | null;
          expires_at?: string | null;
          created_by?: string | null;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['announcements']['Insert']>;
        Relationships: [];
      };
      audit_logs: {
        Row: {
          id: number;
          actor_id: string | null;
          action: string;
          table_name: string;
          record_id: string | null;
          old_data: Json | null;
          new_data: Json | null;
          created_at: string;
        };
        Insert: {
          id?: number;
          actor_id?: string | null;
          action: string;
          table_name: string;
          record_id?: string | null;
          old_data?: Json | null;
          new_data?: Json | null;
          created_at?: string;
        };
        Update: Partial<Database['public']['Tables']['audit_logs']['Insert']>;
        Relationships: [];
      };
      app_settings: {
        Row: {
          key: string;
          value: Json;
          is_public: boolean;
          updated_by: string | null;
          updated_at: string;
        };
        Insert: {
          key: string;
          value: Json;
          is_public?: boolean;
          updated_by?: string | null;
          updated_at?: string;
        };
        Update: Partial<Database['public']['Tables']['app_settings']['Insert']>;
        Relationships: [];
      };
    };
    Views: Record<string, never>;
    Functions: {
      is_admin: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
      is_super_admin: {
        Args: Record<PropertyKey, never>;
        Returns: boolean;
      };
      admin_dashboard_stats: {
        Args: Record<PropertyKey, never>;
        Returns: Json;
      };
      admin_exam_stats: {
        Args: { p_exam_id: string };
        Returns: Json;
      };
    };
    Enums: {
      app_role: AppRole;
      video_provider: VideoProvider;
      material_type: MaterialType;
      material_source: MaterialSource;
      exam_scope: ExamScope;
      exam_mode: ExamMode;
      answer_visibility: AnswerVisibility;
      attempt_status: AttemptStatus;
      difficulty_level: DifficultyLevel;
    };
    CompositeTypes: Record<string, never>;
  };
}
